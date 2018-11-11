require "cxxstdlib"
require "formula"
require "keg"
require "tab"
require "utils/bottles"
require "caveats"
require "cleaner"
require "formula_cellar_checks"
require "install_renamed"
require "debrew"
require "sandbox"
require "emoji"
require "development_tools"
require "cache_store"
require "linkage_checker"
require "install"
require "messages"

class FormulaInstaller
  include FormulaCellarChecks
  extend Predicable

  def self.mode_attr_accessor(*names)
    attr_accessor(*names)
    private(*names)
    names.each do |name|
      predicate = "#{name}?"
      define_method(predicate) do
        send(name) ? true : false
      end
      private(predicate)
    end
  end

  attr_reader :formula
  attr_accessor :options, :build_bottle, :invalid_option_names
  attr_accessor :installed_as_dependency, :installed_on_request, :link_keg
  mode_attr_accessor :show_summary_heading, :show_header
  mode_attr_accessor :build_from_source, :force_bottle, :include_test
  mode_attr_accessor :ignore_deps, :only_deps, :interactive, :git
  mode_attr_accessor :verbose, :debug, :quieter

  def initialize(formula)
    @formula = formula
    @link_keg = !formula.keg_only?
    @show_header = false
    @ignore_deps = false
    @only_deps = false
    @build_from_source = ARGV.build_from_source? || ARGV.build_all_from_source?
    @build_bottle = false
    @force_bottle = ARGV.force_bottle?
    @include_test = ARGV.include?("--include-test")
    @interactive = false
    @git = false
    @verbose = ARGV.verbose?
    @quieter = ARGV.quieter?
    @debug = ARGV.debug?
    @installed_as_dependency = false
    @installed_on_request = true
    @options = Options.new
    @invalid_option_names = []
    @requirement_messages = []
    @poured_bottle = false
    @pour_failed = false
    @start_time = nil
  end

  def self.attempted
    @attempted ||= Set.new
  end

  # When no build tools are available and build flags are passed through ARGV,
  # it's necessary to interrupt the user before any sort of installation
  # can proceed. Only invoked when the user has no developer tools.
  def self.prevent_build_flags
    build_flags = ARGV.collect_build_flags
    return if build_flags.empty?

    all_bottled = ARGV.formulae.all?(&:bottled?)
    raise BuildFlagsError.new(build_flags, bottled: all_bottled)
  end

  def build_bottle?
    return false unless @build_bottle

    !formula.bottle_disabled?
  end

  def pour_bottle?(install_bottle_options = { warn: false })
    return false if @pour_failed

    return false if !formula.bottled? && !formula.local_bottle_path
    return true  if force_bottle?
    return false if build_from_source? || build_bottle? || interactive?
    return false if ARGV.cc
    return false unless options.empty?
    return false if formula.bottle_disabled?

    unless formula.pour_bottle?
      if install_bottle_options[:warn] && formula.pour_bottle_check_unsatisfied_reason
        opoo <<~EOS
          Building #{formula.full_name} from source:
            #{formula.pour_bottle_check_unsatisfied_reason}
        EOS
      end
      return false
    end

    bottle = formula.bottle_specification
    unless bottle.compatible_cellar?
      if install_bottle_options[:warn]
        opoo <<~EOS
          Building #{formula.full_name} from source:
            The bottle needs a #{bottle.cellar} Cellar (yours is #{HOMEBREW_CELLAR}).
        EOS
      end
      return false
    end

    true
  end

  def install_bottle_for?(dep, build)
    return pour_bottle? if dep == formula
    return false if ARGV.build_formula_from_source?(dep)
    return false unless dep.bottle && dep.pour_bottle?
    return false unless build.used_options.empty?
    return false unless dep.bottle.compatible_cellar?

    true
  end

  def prelude
    Tab.clear_cache
    verify_deps_exist unless ignore_deps?
    lock
    check_install_sanity
  end

  def verify_deps_exist
    begin
      compute_dependencies
    rescue TapFormulaUnavailableError => e
      raise if e.tap.installed?

      e.tap.install
      retry
    end
  rescue FormulaUnavailableError => e
    e.dependent = formula.full_name
    raise
  end

  def check_install_sanity
    raise FormulaInstallationAlreadyAttemptedError, formula if self.class.attempted.include?(formula)

    return if ignore_deps?

    recursive_deps = formula.recursive_dependencies
    recursive_formulae = recursive_deps.map(&:to_formula)

    recursive_dependencies = []
    recursive_formulae.each do |dep|
      dep_recursive_dependencies = dep.recursive_dependencies.map(&:to_s)
      if dep_recursive_dependencies.include?(formula.name)
        recursive_dependencies << "#{formula.full_name} depends on #{dep.full_name}"
        recursive_dependencies << "#{dep.full_name} depends on #{formula.full_name}"
      end
    end

    unless recursive_dependencies.empty?
      raise CannotInstallFormulaError, <<~EOS
        #{formula.full_name} contains a recursive dependency on itself:
          #{recursive_dependencies.join("\n  ")}
      EOS
    end

    if recursive_formulae.flat_map(&:recursive_dependencies)
                         .map(&:to_s)
                         .include?(formula.name)
      raise CannotInstallFormulaError, <<~EOS
        #{formula.full_name} contains a recursive dependency on itself!
      EOS
    end

    pinned_unsatisfied_deps = recursive_deps.select do |dep|
      dep.to_formula.pinned? && !dep.satisfied?(inherited_options_for(dep))
    end

    return if pinned_unsatisfied_deps.empty?

    raise CannotInstallFormulaError,
      "You must `brew unpin #{pinned_unsatisfied_deps * " "}` as installing " \
      "#{formula.full_name} requires the latest version of pinned dependencies"
  end

  def build_bottle_preinstall
    @etc_var_glob ||= "#{HOMEBREW_PREFIX}/{etc,var}/**/*"
    @etc_var_preinstall = Dir[@etc_var_glob]
  end

  def build_bottle_postinstall
    @etc_var_postinstall = Dir[@etc_var_glob]
    (@etc_var_postinstall - @etc_var_preinstall).each do |file|
      Pathname.new(file).cp_path_sub(HOMEBREW_PREFIX, formula.bottle_prefix)
    end
  end

  def install
    start_time = Time.now
    if !formula.bottle_unneeded? && !pour_bottle? && DevelopmentTools.installed?
      Homebrew::Install.perform_development_tools_checks
    end

    # not in initialize so upgrade can unlink the active keg before calling this
    # function but after instantiating this class so that it can avoid having to
    # relink the active keg if possible (because it is slow).
    if formula.linked_keg.directory?
      message = <<~EOS
        #{formula.name} #{formula.linked_version} is already installed
      EOS
      if formula.outdated? && !formula.head?
        message += <<~EOS
          To upgrade to #{formula.pkg_version}, run `brew upgrade #{formula.name}`
        EOS
      elsif only_deps?
        message = nil
      else
        # some other version is already installed *and* linked
        message += <<~EOS
          To install #{formula.pkg_version}, first run `brew unlink #{formula.name}`
        EOS
      end
      raise CannotInstallFormulaError, message if message
    end

    # Warn if a more recent version of this formula is available in the tap.
    begin
      if formula.pkg_version < (v = Formulary.factory(formula.full_name).pkg_version)
        opoo "#{formula.full_name} #{v} is available and more recent than version #{formula.pkg_version}."
      end
    rescue FormulaUnavailableError
      nil
    end

    check_conflicts

    if !pour_bottle? && !formula.bottle_unneeded? && !DevelopmentTools.installed?
      raise BuildToolsError, [formula]
    end

    unless ignore_deps?
      deps = compute_dependencies
      check_dependencies_bottled(deps) if pour_bottle? && !DevelopmentTools.installed?
      install_dependencies(deps)
    end

    return if only_deps?

    if build_bottle? && (arch = ARGV.bottle_arch) && !Hardware::CPU.optimization_flags.include?(arch)
      raise "Unrecognized architecture for --bottle-arch: #{arch}"
    end

    formula.deprecated_flags.each do |deprecated_option|
      old_flag = deprecated_option.old_flag
      new_flag = deprecated_option.current_flag
      opoo "#{formula.full_name}: #{old_flag} was deprecated; using #{new_flag} instead!"
    end

    invalid_option_names.each do |option|
      opoo "#{formula.full_name}: this formula has no #{option} option so it will be ignored!"
    end

    options = display_options(formula)
    if show_header?
      oh1 "Installing #{Formatter.identifier(formula.full_name)} #{options}".strip
    end

    unless formula.tap&.private?
      action = "#{formula.full_name} #{options}".strip
      Utils::Analytics.report_event("install", action)

      if installed_on_request
        Utils::Analytics.report_event("install_on_request", action)
      end
    end

    self.class.attempted << formula

    if pour_bottle?(warn: true)
      begin
        pour
      rescue Exception => e # rubocop:disable Lint/RescueException
        # any exceptions must leave us with nothing installed
        ignore_interrupts do
          formula.prefix.rmtree if formula.prefix.directory?
          formula.rack.rmdir_if_possible
        end
        raise if ARGV.homebrew_developer? || e.is_a?(Interrupt)

        @pour_failed = true
        onoe e.message
        opoo "Bottle installation failed: building from source."
        raise BuildToolsError, [formula] unless DevelopmentTools.installed?

        compute_and_install_dependencies unless ignore_deps?
      else
        @poured_bottle = true
      end
    end

    puts_requirement_messages

    build_bottle_preinstall if build_bottle?

    unless @poured_bottle
      build
      clean

      # Store the formula used to build the keg in the keg.
      formula_contents = if formula.local_bottle_path
        Utils::Bottles.formula_contents formula.local_bottle_path, name: formula.name
      else
        formula.path.read
      end
      s = formula_contents.gsub(/  bottle do.+?end\n\n?/m, "")
      brew_prefix = formula.prefix/".brew"
      brew_prefix.mkdir
      Pathname(brew_prefix/"#{formula.name}.rb").atomic_write(s)

      keg = Keg.new(formula.prefix)
      tab = Tab.for_keg(keg)
      tab.installed_as_dependency = installed_as_dependency
      tab.installed_on_request = installed_on_request
      tab.write
    end

    build_bottle_postinstall if build_bottle?

    opoo "Nothing was installed to #{formula.prefix}" unless formula.installed?
    end_time = Time.now
    Homebrew.messages.formula_installed(formula, end_time - start_time)
  end

  def check_conflicts
    return if ARGV.force?

    conflicts = formula.conflicts.select do |c|
      begin
        f = Formulary.factory(c.name)
      rescue TapFormulaUnavailableError
        # If the formula name is a fully-qualified name let's silently
        # ignore it as we don't care about things used in taps that aren't
        # currently tapped.
        false
      rescue FormulaUnavailableError => e
        # If the formula name doesn't exist any more then complain but don't
        # stop installation from continuing.
        opoo <<~EOS
          #{formula}: #{e.message}
          'conflicts_with \"#{c.name}\"' should be removed from #{formula.path.basename}.
        EOS

        raise if ARGV.homebrew_developer?

        $stderr.puts "Please report this to the #{formula.tap} tap!"
        false
      else
        f.linked_keg.exist? && f.opt_prefix.exist?
      end
    end

    raise FormulaConflictError.new(formula, conflicts) unless conflicts.empty?
  end

  # Compute and collect the dependencies needed by the formula currently
  # being installed.
  def compute_dependencies
    req_map, req_deps = expand_requirements
    check_requirements(req_map)
    deps = expand_dependencies(req_deps + formula.deps)

    deps
  end

  # Check that each dependency in deps has a bottle available, terminating
  # abnormally with a BuildToolsError if one or more don't.
  # Only invoked when the user has no developer tools.
  def check_dependencies_bottled(deps)
    unbottled = deps.reject do |dep, _|
      dep_f = dep.to_formula
      dep_f.pour_bottle? || dep_f.bottle_unneeded?
    end

    raise BuildToolsError, unbottled unless unbottled.empty?
  end

  def compute_and_install_dependencies
    deps = compute_dependencies
    install_dependencies(deps)
  end

  def check_requirements(req_map)
    @requirement_messages = []
    fatals = []

    req_map.each_pair do |dependent, reqs|
      reqs.each do |req|
        next if dependent.installed? && req.name == "maximummacos"

        @requirement_messages << "#{dependent}: #{req.message}"
        fatals << req if req.fatal?
      end
    end

    return if fatals.empty?

    puts_requirement_messages
    raise UnsatisfiedRequirements, fatals
  end

  def runtime_requirements(formula)
    runtime_deps = formula.runtime_formula_dependencies(undeclared: false)
    recursive_requirements = formula.recursive_requirements do |dependent, _|
      Requirement.prune unless runtime_deps.include?(dependent)
    end
    (recursive_requirements.to_a + formula.requirements.to_a).reject(&:build?).uniq
  end

  def expand_requirements
    unsatisfied_reqs = Hash.new { |h, k| h[k] = [] }
    req_deps = []
    formulae = [formula]
    formula_deps_map = Dependency.expand(formula)
                                 .each_with_object({}) do |dep, hash|
      hash[dep.name] = dep
    end

    while f = formulae.pop
      runtime_requirements = runtime_requirements(f)
      f.recursive_requirements do |dependent, req|
        build = effective_build_options_for(dependent)
        install_bottle_for_dependent = install_bottle_for?(dependent, build)

        if req.prune_from_option?(build)
          Requirement.prune
        elsif req.satisfied?
          Requirement.prune
        elsif include_test? && req.test?
          next
        elsif !runtime_requirements.include?(req) && install_bottle_for_dependent
          Requirement.prune
        elsif (dep = formula_deps_map[dependent.name]) && dep.build?
          Requirement.prune
        else
          unsatisfied_reqs[dependent] << req
        end
      end
    end

    # Merge the repeated dependencies, which may have different tags.
    req_deps = Dependency.merge_repeats(req_deps)

    [unsatisfied_reqs, req_deps]
  end

  def expand_dependencies(deps)
    inherited_options = Hash.new { |hash, key| hash[key] = Options.new }
    pour_bottle = pour_bottle?

    expanded_deps = Dependency.expand(formula, deps) do |dependent, dep|
      inherited_options[dep.name] |= inherited_options_for(dep)
      build = effective_build_options_for(
        dependent,
        inherited_options.fetch(dependent.name, []),
      )
      pour_bottle = true if install_bottle_for?(dep.to_formula, build)

      if dep.prune_from_option?(build)
        Dependency.prune
      elsif include_test? && dep.test? && !dep.installed?
        Dependency.keep_but_prune_recursive_deps
      elsif dep.build? && install_bottle_for?(dependent, build)
        Dependency.prune
      elsif dep.prune_if_build_and_not_dependent?(dependent)
        Dependency.prune
      elsif dep.satisfied?(inherited_options[dep.name])
        Dependency.skip
      end
    end

    if pour_bottle && !Keg.bottle_dependencies.empty?
      bottle_deps = if !Keg.bottle_dependencies.include?(formula.name)
        Keg.bottle_dependencies
      elsif !Keg.relocation_formulae.include?(formula.name)
        Keg.relocation_formulae
      else
        []
      end
      bottle_deps = bottle_deps.map { |formula| Dependency.new(formula) }
                               .reject do |dep|
        inherited_options[dep.name] |= inherited_options_for(dep)
        dep.satisfied? inherited_options[dep.name]
      end
      expanded_deps = Dependency.merge_repeats(bottle_deps + expanded_deps)
    end

    expanded_deps.map { |dep| [dep, inherited_options[dep.name]] }
  end

  def effective_build_options_for(dependent, inherited_options = [])
    args  = dependent.build.used_options
    args |= (dependent == formula) ? options : inherited_options
    args |= Tab.for_formula(dependent).used_options
    args &= dependent.options
    BuildOptions.new(args, dependent.options)
  end

  def display_options(formula)
    options = []
    if formula.head?
      options << "--HEAD"
    elsif formula.devel?
      options << "--devel"
    end
    options += effective_build_options_for(formula).used_options.to_a
    return if options.empty?

    options.join(" ")
  end

  def inherited_options_for(dep)
    inherited_options = Options.new
    u = Option.new("universal")
    if (options.include?(u) || formula.require_universal_deps?) && !dep.build? && dep.to_formula.option_defined?(u)
      inherited_options << u
    end
    inherited_options
  end

  def install_dependencies(deps)
    if deps.empty? && only_deps?
      puts "All dependencies for #{formula.full_name} are satisfied."
    elsif !deps.empty?
      oh1 "Installing dependencies for #{formula.full_name}: " \
          "#{deps.map(&:first).map(&Formatter.method(:identifier)).to_sentence}",
          truncate: false
      deps.each { |dep, options| install_dependency(dep, options) }
    end

    @show_header = true unless deps.empty?
  end

  def install_dependency(dep, inherited_options)
    df = dep.to_formula
    tab = Tab.for_formula(df)

    if df.linked_keg.directory?
      linked_keg = Keg.new(df.linked_keg.resolved_path)
      keg_had_linked_keg = true
      keg_was_linked = linked_keg.linked?
      linked_keg.unlink
    end

    if df.installed?
      installed_keg = Keg.new(df.prefix)
      tmp_keg = Pathname.new("#{installed_keg}.tmp")
      installed_keg.rename(tmp_keg)
    end

    tab_tap = tab.source["tap"]
    if df.tap.to_s != tab_tap
      odie <<~EOS
        #{df} is already installed from #{tab_tap}!
        Please `brew uninstall #{df}` first."
      EOS
    end

    fi = FormulaInstaller.new(df)
    fi.options                |= tab.used_options
    fi.options                |= Tab.remap_deprecated_options(df.deprecated_options, dep.options)
    fi.options                |= inherited_options
    fi.options                &= df.options
    fi.build_from_source       = ARGV.build_formula_from_source?(df)
    fi.force_bottle            = false
    fi.verbose                 = verbose?
    fi.quieter                 = quieter?
    fi.debug                   = debug?
    fi.link_keg              ||= keg_was_linked if keg_had_linked_keg
    fi.installed_as_dependency = true
    fi.installed_on_request    = df.any_version_installed? && tab.installed_on_request
    fi.prelude
    oh1 "Installing #{formula.full_name} dependency: #{Formatter.identifier(dep.name)}"
    fi.install
    fi.finish
  rescue Exception # rubocop:disable Lint/RescueException
    ignore_interrupts do
      tmp_keg.rename(installed_keg) if tmp_keg && !installed_keg.directory?
      linked_keg.link if keg_was_linked
    end
    raise
  else
    ignore_interrupts { tmp_keg.rmtree if tmp_keg&.directory? }
  end

  def caveats
    return if only_deps?

    audit_installed if ARGV.homebrew_developer?

    caveats = Caveats.new(formula)

    return if caveats.empty?

    @show_summary_heading = true
    ohai "Caveats", caveats.to_s
    Homebrew.messages.record_caveats(formula, caveats)
  end

  def finish
    return if only_deps?

    ohai "Finishing up" if verbose?

    install_plist

    keg = Keg.new(formula.prefix)
    link(keg)

    unless @poured_bottle && formula.bottle_specification.skip_relocation?
      fix_dynamic_linkage(keg)
    end

    if build_bottle?
      ohai "Not running post_install as we're building a bottle"
      puts "You can run it manually using `brew postinstall #{formula.full_name}`"
    else
      post_install
    end

    # Updates the cache for a particular formula after doing an install
    CacheStoreDatabase.use(:linkage) do |db|
      break unless db.created?

      LinkageChecker.new(keg, formula, cache_db: db, rebuild_cache: true)
    end

    # Update tab with actual runtime dependencies
    tab = Tab.for_keg(keg)
    Tab.clear_cache
    f_runtime_deps = formula.runtime_dependencies(read_from_tab: false)
    tab.runtime_dependencies = Tab.runtime_deps_hash(f_runtime_deps)
    tab.write

    # let's reset Utils.git_available? if we just installed git
    Utils.clear_git_available_cache if formula.name == "git"

    # use installed curl when it's needed and available
    if formula.name == "curl" &&
       !DevelopmentTools.curl_handles_most_https_certificates?
      ENV["HOMEBREW_CURL"] = formula.opt_bin/"curl"
    end

    caveats

    ohai "Summary" if verbose? || show_summary_heading?
    puts summary
  ensure
    unlock
  end

  def summary
    s = ""
    s << "#{Emoji.install_badge}  " if Emoji.enabled?
    s << "#{formula.prefix.resolved_path}: #{formula.prefix.abv}"
    s << ", built in #{pretty_duration build_time}" if build_time
    s
  end

  def build_time
    @build_time ||= Time.now - @start_time if @start_time && !interactive?
  end

  def sanitized_argv_options
    args = []
    args << "--ignore-dependencies" if ignore_deps?

    if build_bottle?
      args << "--build-bottle"
      args << "--bottle-arch=#{ARGV.bottle_arch}" if ARGV.bottle_arch
    end

    args << "--git" if git?
    args << "--interactive" if interactive?
    args << "--verbose" if verbose?
    args << "--debug" if debug?
    args << "--cc=#{ARGV.cc}" if ARGV.cc
    args << "--default-fortran-flags" if ARGV.include? "--default-fortran-flags"
    args << "--keep-tmp" if ARGV.keep_tmp?

    if ARGV.env
      args << "--env=#{ARGV.env}"
    elsif formula.env.std? || formula.deps.select(&:build?).any? { |d| d.name == "scons" }
      args << "--env=std"
    end

    if formula.head?
      args << "--HEAD"
    elsif formula.devel?
      args << "--devel"
    end

    formula.options.each do |opt|
      name = opt.name[/^([^=]+)=$/, 1]
      value = ARGV.value(name) if name
      args << "--#{name}=#{value}" if value
    end

    args
  end

  def build_argv
    sanitized_argv_options + options.as_flags
  end

  def build
    FileUtils.rm_rf(formula.logs)

    @start_time = Time.now

    # 1. formulae can modify ENV, so we must ensure that each
    #    installation has a pristine ENV when it starts, forking now is
    #    the easiest way to do this
    args = %W[
      nice #{RUBY_PATH}
      -W0
      -I #{$LOAD_PATH.join(File::PATH_SEPARATOR)}
      --
      #{HOMEBREW_LIBRARY_PATH}/build.rb
      #{formula.specified_path}
    ].concat(build_argv)

    Utils.safe_fork do
      # Invalidate the current sudo timestamp in case a build script calls sudo.
      # Travis CI's Linux sudoless workers have a weird sudo that fails here.
      system "/usr/bin/sudo", "-k" if ENV["HOMEBREW_TRAVIS_SUDO"] != "false"

      if Sandbox.formula?(formula)
        sandbox = Sandbox.new
        formula.logs.mkpath
        sandbox.record_log(formula.logs/"build.sandbox.log")
        sandbox.allow_write_path(ENV["HOME"]) if ARGV.interactive?
        sandbox.allow_write_temp_and_cache
        sandbox.allow_write_log(formula)
        sandbox.allow_cvs
        sandbox.allow_fossil
        sandbox.allow_write_xcode
        sandbox.allow_write_cellar(formula)
        sandbox.exec(*args)
      else
        exec(*args)
      end
    end

    formula.update_head_version

    if !formula.prefix.directory? || Keg.new(formula.prefix).empty_installation?
      raise "Empty installation"
    end
  rescue Exception => e # rubocop:disable Lint/RescueException
    if e.is_a? BuildError
      e.formula = formula
      e.options = options
    end

    ignore_interrupts do
      # any exceptions must leave us with nothing installed
      formula.update_head_version
      formula.prefix.rmtree if formula.prefix.directory?
      formula.rack.rmdir_if_possible
    end
    raise e
  end

  def link(keg)
    unless link_keg
      begin
        keg.optlink
      rescue Keg::LinkError => e
        onoe "Failed to create #{formula.opt_prefix}"
        puts "Things that depend on #{formula.full_name} will probably not build."
        puts e
        Homebrew.failed = true
      end
      return
    end

    if keg.linked?
      opoo "This keg was marked linked already, continuing anyway"
      keg.remove_linked_keg_record
    end

    link_overwrite_backup = {} # Hash: conflict file -> backup file
    backup_dir = HOMEBREW_CACHE/"Backup"

    begin
      keg.link
    rescue Keg::ConflictError => e
      conflict_file = e.dst
      if formula.link_overwrite?(conflict_file) && !link_overwrite_backup.key?(conflict_file)
        backup_file = backup_dir/conflict_file.relative_path_from(HOMEBREW_PREFIX).to_s
        backup_file.parent.mkpath
        conflict_file.rename backup_file
        link_overwrite_backup[conflict_file] = backup_file
        retry
      end
      onoe "The `brew link` step did not complete successfully"
      puts "The formula built, but is not symlinked into #{HOMEBREW_PREFIX}"
      puts e
      puts
      puts "Possible conflicting files are:"
      mode = OpenStruct.new(dry_run: true, overwrite: true)
      keg.link(mode)
      @show_summary_heading = true
      Homebrew.failed = true
    rescue Keg::LinkError => e
      onoe "The `brew link` step did not complete successfully"
      puts "The formula built, but is not symlinked into #{HOMEBREW_PREFIX}"
      puts e
      puts
      puts "You can try again using:"
      puts "  brew link #{formula.name}"
      @show_summary_heading = true
      Homebrew.failed = true
    rescue Exception => e # rubocop:disable Lint/RescueException
      onoe "An unexpected error occurred during the `brew link` step"
      puts "The formula built, but is not symlinked into #{HOMEBREW_PREFIX}"
      puts e
      puts e.backtrace if debug?
      @show_summary_heading = true
      ignore_interrupts do
        keg.unlink
        link_overwrite_backup.each do |origin, backup|
          origin.parent.mkpath
          backup.rename origin
        end
      end
      Homebrew.failed = true
      raise
    end

    return if link_overwrite_backup.empty?

    opoo "These files were overwritten during `brew link` step:"
    puts link_overwrite_backup.keys
    puts
    puts "They have been backed up in #{backup_dir}"
    @show_summary_heading = true
  end

  def install_plist
    return unless formula.plist

    formula.plist_path.atomic_write(formula.plist)
    formula.plist_path.chmod 0644
    log = formula.var/"log"
    log.mkpath if formula.plist.include? log.to_s
  rescue Exception => e # rubocop:disable Lint/RescueException
    onoe "Failed to install plist file"
    ohai e, e.backtrace if debug?
    Homebrew.failed = true
  end

  def fix_dynamic_linkage(keg)
    keg.fix_dynamic_linkage
  rescue Exception => e # rubocop:disable Lint/RescueException
    onoe "Failed to fix install linkage"
    puts "The formula built, but you may encounter issues using it or linking other"
    puts "formula against it."
    ohai e, e.backtrace if debug?
    Homebrew.failed = true
    @show_summary_heading = true
  end

  def clean
    ohai "Cleaning" if verbose?
    Cleaner.new(formula).clean
  rescue Exception => e # rubocop:disable Lint/RescueException
    opoo "The cleaning step did not complete successfully"
    puts "Still, the installation was successful, so we will link it into your prefix"
    ohai e, e.backtrace if debug?
    Homebrew.failed = true
    @show_summary_heading = true
  end

  def post_install
    args = %W[
      nice #{RUBY_PATH}
      -W0
      -I #{$LOAD_PATH.join(File::PATH_SEPARATOR)}
      --
      #{HOMEBREW_LIBRARY_PATH}/postinstall.rb
      #{formula.path}
    ].concat(ARGV.options_only) - ["--HEAD", "--devel"]

    if formula.head?
      args << "--HEAD"
    elsif formula.devel?
      args << "--devel"
    end

    Utils.safe_fork do
      if Sandbox.formula?(formula)
        sandbox = Sandbox.new
        formula.logs.mkpath
        sandbox.record_log(formula.logs/"postinstall.sandbox.log")
        sandbox.allow_write_temp_and_cache
        sandbox.allow_write_log(formula)
        sandbox.allow_write_xcode
        sandbox.deny_write_homebrew_repository
        sandbox.allow_write_cellar(formula)
        Keg::KEG_LINK_DIRECTORIES.each do |dir|
          sandbox.allow_write_path "#{HOMEBREW_PREFIX}/#{dir}"
        end
        sandbox.exec(*args)
      else
        exec(*args)
      end
    end
  rescue Exception => e # rubocop:disable Lint/RescueException
    opoo "The post-install step did not complete successfully"
    puts "You can try again using `brew postinstall #{formula.full_name}`"
    ohai e, e.backtrace if debug? || ARGV.homebrew_developer?
    Homebrew.failed = true
    @show_summary_heading = true
  end

  def pour
    if (bottle_path = formula.local_bottle_path)
      downloader = LocalBottleDownloadStrategy.new(bottle_path)
    else
      downloader = formula.bottle
      downloader.verify_download_integrity(downloader.fetch)
    end
    HOMEBREW_CELLAR.cd do
      downloader.stage
    end

    keg = Keg.new(formula.prefix)
    tab = Tab.for_keg(keg)
    Tab.clear_cache

    skip_linkage = formula.bottle_specification.skip_relocation?
    keg.replace_placeholders_with_locations tab.changed_files, skip_linkage: skip_linkage

    tab = Tab.for_keg(keg)

    CxxStdlib.check_compatibility(
      formula, formula.recursive_dependencies,
      Keg.new(formula.prefix), tab.compiler
    )

    tab.tap = formula.tap
    tab.poured_from_bottle = true
    tab.time = Time.now.to_i
    tab.head = HOMEBREW_REPOSITORY.git_head
    tab.source["path"] = formula.specified_path.to_s
    tab.installed_as_dependency = installed_as_dependency
    tab.installed_on_request = installed_on_request
    tab.aliases = formula.aliases
    tab.write
  end

  def problem_if_output(output)
    return unless output

    opoo output
    @show_summary_heading = true
  end

  def audit_installed
    unless formula.keg_only?
      problem_if_output(check_env_path(formula.bin))
      problem_if_output(check_env_path(formula.sbin))
    end
    super
  end

  def self.locked
    @locked ||= []
  end

  private

  attr_predicate :hold_locks?

  def lock
    return unless self.class.locked.empty?

    unless ignore_deps?
      formula.recursive_dependencies.each do |dep|
        self.class.locked << dep.to_formula
      end
    end
    self.class.locked.unshift(formula)
    self.class.locked.uniq!
    self.class.locked.each(&:lock)
    @hold_locks = true
  end

  def unlock
    return unless hold_locks?

    self.class.locked.each(&:unlock)
    self.class.locked.clear
    @hold_locks = false
  end

  def puts_requirement_messages
    return unless @requirement_messages
    return if @requirement_messages.empty?

    $stderr.puts @requirement_messages
  end
end
