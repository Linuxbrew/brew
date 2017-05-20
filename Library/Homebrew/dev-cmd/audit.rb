#:  * `audit` [`--strict`] [`--fix`] [`--online`] [`--new-formula`] [`--display-cop-names`] [`--display-filename`] [`--only=`<method>|`--except=`<method>] [`--only-cops=`[COP1,COP2..]|`--except-cops=`[COP1,COP2..]] [<formulae>]:
#:    Check <formulae> for Homebrew coding style violations. This should be
#:    run before submitting a new formula.
#:
#:    If no <formulae> are provided, all of them are checked.
#:
#:    If `--strict` is passed, additional checks are run, including RuboCop
#:    style checks.
#:
#:    If `--fix` is passed, style violations will be
#:    automatically fixed using RuboCop's `--auto-correct` feature.
#:
#:    If `--online` is passed, additional slower checks that require a network
#:    connection are run.
#:
#:    If `--new-formula` is passed, various additional checks are run that check
#:    if a new formula is eligible for Homebrew. This should be used when creating
#:    new formulae and implies `--strict` and `--online`.
#:
#:    If `--display-cop-names` is passed, the RuboCop cop name for each violation
#:    is included in the output.
#:
#:    If `--display-filename` is passed, every line of output is prefixed with the
#:    name of the file or formula being audited, to make the output easy to grep.
#:
#:    If `--only` is passed, only the methods named `audit_<method>` will be run.
#:
#:    If `--except` is passed, the methods named `audit_<method>` will not be run.
#:
#:    If `--only-cops` is passed, only the given Rubocop cop(s)' violations would be checked.
#:
#:    If `--except-cops` is passed, the given Rubocop cop(s)' checks would be skipped.
#:
#:    `audit` exits with a non-zero status if any errors are found. This is useful,
#:    for instance, for implementing pre-commit hooks.

# Undocumented options:
#     -D activates debugging and profiling of the audit methods (not the same as --debug)

require "formula"
require "formula_versions"
require "utils"
require "extend/ENV"
require "formula_cellar_checks"
require "official_taps"
require "cmd/search"
require "cmd/style"
require "date"
require "missing_formula"
require "digest"

module Homebrew
  module_function

  def audit
    Homebrew.inject_dump_stats!(FormulaAuditor, /^audit_/) if ARGV.switch? "D"

    formula_count = 0
    problem_count = 0

    new_formula = ARGV.include? "--new-formula"
    strict = new_formula || ARGV.include?("--strict")
    online = new_formula || ARGV.include?("--online")

    ENV.activate_extensions!
    ENV.setup_build_environment

    if ARGV.named.empty?
      ff = Formula
      files = Tap.map(&:formula_dir)
    else
      ff = ARGV.resolved_formulae
      files = ARGV.resolved_formulae.map(&:path)
    end

    only_cops = ARGV.value("only-cops").to_s.split(",")
    except_cops = ARGV.value("except-cops").to_s.split(",")
    if !only_cops.empty? && !except_cops.empty?
      odie "--only-cops and --except-cops cannot be used simultaneously!"
    elsif (!only_cops.empty? || !except_cops.empty?) && strict
      odie "--only-cops/--except-cops and --strict cannot be used simultaneously"
    end

    options = { fix: ARGV.flag?("--fix"), realpath: true }

    if !only_cops.empty?
      options[:only_cops] = only_cops
    elsif !except_cops.empty?
      options[:except_cops] = except_cops
    elsif !strict
      options[:except_cops] = [:FormulaAuditStrict]
    end

    # Check style in a single batch run up front for performance
    style_results = check_style_json(files, options)

    ff.each do |f|
      options = { new_formula: new_formula, strict: strict, online: online }
      options[:style_offenses] = style_results.file_offenses(f.path)
      fa = FormulaAuditor.new(f, options)
      fa.audit

      next if fa.problems.empty?
      fa.problems
      formula_count += 1
      problem_count += fa.problems.size
      problem_lines = fa.problems.map { |p| "* #{p.chomp.gsub("\n", "\n    ")}" }
      if ARGV.include? "--display-filename"
        puts problem_lines.map { |s| "#{f.path}: #{s}" }
      else
        puts "#{f.full_name}:", problem_lines.map { |s| "  #{s}" }
      end
    end

    return if problem_count.zero?

    ofail "#{Formatter.pluralize(problem_count, "problem")} in #{Formatter.pluralize(formula_count, "formula")}"
  end
end

class FormulaText
  def initialize(path)
    @text = path.open("rb", &:read)
    @lines = @text.lines.to_a
  end

  def without_patch
    @text.split("\n__END__").first
  end

  def data?
    /^[^#]*\bDATA\b/ =~ @text
  end

  def end?
    /^__END__$/ =~ @text
  end

  def trailing_newline?
    /\Z\n/ =~ @text
  end

  def =~(other)
    other =~ @text
  end

  def include?(s)
    @text.include? s
  end

  def line_number(regex, skip = 0)
    index = @lines.drop(skip).index { |line| line =~ regex }
    index ? index + 1 : nil
  end

  def reverse_line_number(regex)
    index = @lines.reverse.index { |line| line =~ regex }
    index ? @lines.count - index : nil
  end
end

class FormulaAuditor
  include FormulaCellarChecks

  attr_reader :formula, :text, :problems

  BUILD_TIME_DEPS = %w[
    autoconf
    automake
    boost-build
    bsdmake
    cmake
    godep
    imake
    intltool
    libtool
    pkg-config
    scons
    smake
    sphinx-doc
    swig
  ].freeze

  FILEUTILS_METHODS = FileUtils.singleton_methods(false).map { |m| Regexp.escape(m) }.join "|"

  def initialize(formula, options = {})
    @formula = formula
    @new_formula = options[:new_formula]
    @strict = options[:strict]
    @online = options[:online]
    # Accept precomputed style offense results, for efficiency
    @style_offenses = options[:style_offenses]
    @problems = []
    @text = FormulaText.new(formula.path)
    @specs = %w[stable devel head].map { |s| formula.send(s) }.compact
  end

  def self.check_http_content(url, user_agents: [:default])
    return unless url.start_with? "http"

    details = nil
    user_agent = nil
    hash_needed = url.start_with?("http:")
    user_agents.each do |ua|
      details = http_content_headers_and_checksum(url, hash_needed: hash_needed, user_agent: ua)
      user_agent = ua
      break if details[:status].to_s.start_with?("2")
    end

    return "The URL #{url} is not reachable" unless details[:status]
    unless details[:status].start_with? "2"
      return "The URL #{url} is not reachable (HTTP status code #{details[:status]})"
    end

    return unless hash_needed

    secure_url = url.sub "http", "https"
    secure_details =
      http_content_headers_and_checksum(secure_url, hash_needed: true, user_agent: user_agent)

    if !details[:status].to_s.start_with?("2") ||
       !secure_details[:status].to_s.start_with?("2")
      return
    end

    etag_match = details[:etag] &&
                 details[:etag] == secure_details[:etag]
    content_length_match =
      details[:content_length] &&
      details[:content_length] == secure_details[:content_length]
    file_match = details[:file_hash] == secure_details[:file_hash]

    return if !etag_match && !content_length_match && !file_match
    "The URL #{url} could use HTTPS rather than HTTP"
  end

  def self.http_content_headers_and_checksum(url, hash_needed: false, user_agent: :default)
    max_time = hash_needed ? "600" : "25"
    args = curl_args(
      extra_args: ["--connect-timeout", "15", "--include", "--max-time", max_time, url],
      show_output: true,
      user_agent: user_agent,
    )
    output = Open3.popen3(*args) { |_, stdout, _, _| stdout.read }

    status_code = :unknown
    while status_code == :unknown || status_code.to_s.start_with?("3")
      headers, _, output = output.partition("\r\n\r\n")
      status_code = headers[%r{HTTP\/.* (\d+)}, 1]
    end

    output_hash = Digest::SHA256.digest(output) if hash_needed

    {
      status: status_code,
      etag: headers[%r{ETag: ([wW]\/)?"(([^"]|\\")*)"}, 2],
      content_length: headers[/Content-Length: (\d+)/, 1],
      file_hash: output_hash,
    }
  end

  def audit_style
    return unless @style_offenses
    display_cop_names = ARGV.include?("--display-cop-names")
    @style_offenses.each do |offense|
      problem offense.to_s(display_cop_name: display_cop_names)
    end
  end

  def audit_file
    # Under normal circumstances (umask 0022), we expect a file mode of 644. If
    # the user's umask is more restrictive, respect that by masking out the
    # corresponding bits. (The also included 0100000 flag means regular file.)
    wanted_mode = 0100644 & ~File.umask
    actual_mode = formula.path.stat.mode
    unless actual_mode == wanted_mode
      problem format("Incorrect file permissions (%03o): chmod %03o %s",
                     actual_mode & 0777, wanted_mode & 0777, formula.path)
    end

    problem "'DATA' was found, but no '__END__'" if text.data? && !text.end?

    if text.end? && !text.data?
      problem "'__END__' was found, but 'DATA' is not used"
    end

    if text =~ /inreplace [^\n]* do [^\n]*\n[^\n]*\.gsub![^\n]*\n\ *end/m
      problem "'inreplace ... do' was used for a single substitution (use the non-block form instead)."
    end

    problem "File should end with a newline" unless text.trailing_newline?

    if formula.versioned_formula?
      unversioned_formula = begin
        # build this ourselves as we want e.g. homebrew/core to be present
        full_name = if formula.tap
          "#{formula.tap}/#{formula.name}"
        else
          formula.name
        end
        Formulary.factory(full_name.gsub(/@.*$/, "")).path
      rescue FormulaUnavailableError, TapFormulaAmbiguityError,
             TapFormulaWithOldnameAmbiguityError
        Pathname.new formula.path.to_s.gsub(/@.*\.rb$/, ".rb")
      end
      unless unversioned_formula.exist?
        unversioned_name = unversioned_formula.basename(".rb")
        problem "#{formula} is versioned but no #{unversioned_name} formula exists"
      end
    elsif ARGV.build_stable? &&
          !(versioned_formulae = Dir[formula.path.to_s.gsub(/\.rb$/, "@*.rb")]).empty?
      versioned_aliases = formula.aliases.grep(/.@\d/)
      _, last_alias_version =
        File.basename(versioned_formulae.sort.reverse.first)
            .gsub(/\.rb$/, "").split("@")
      major, minor, = formula.version.to_s.split(".")
      alias_name_major = "#{formula.name}@#{major}"
      alias_name_major_minor = "#{alias_name_major}.#{minor}"
      alias_name = if last_alias_version.split(".").length == 1
        alias_name_major
      else
        alias_name_major_minor
      end
      valid_alias_names = [alias_name_major, alias_name_major_minor]

      if formula.tap
        valid_alias_names.map! { |a| "#{formula.tap}/#{a}" }
      end

      valid_versioned_aliases = versioned_aliases & valid_alias_names
      invalid_versioned_aliases = versioned_aliases - valid_alias_names

      if valid_versioned_aliases.empty?
        if formula.tap
          problem <<-EOS.undent
            Formula has other versions so create a versioned alias:
              cd #{formula.tap.alias_dir}
              ln -s #{formula.path.to_s.gsub(formula.tap.path, "..")} #{alias_name}
          EOS
        else
          problem "Formula has other versions so create an alias named #{alias_name}."
        end
      end

      unless invalid_versioned_aliases.empty?
        problem <<-EOS.undent
          Formula has invalid versioned aliases:
            #{invalid_versioned_aliases.join("\n  ")}
        EOS
      end
    end
  end

  def audit_class
    if @strict
      unless formula.test_defined?
        problem "A `test do` test block should be added"
      end
    end

    classes = %w[GithubGistFormula ScriptFileFormula AmazonWebServicesFormula]
    klass = classes.find do |c|
      Object.const_defined?(c) && formula.class < Object.const_get(c)
    end

    problem "#{klass} is deprecated, use Formula instead" if klass
  end

  # core aliases + tap alias names + tap alias full name
  @@aliases ||= Formula.aliases + Formula.tap_aliases

  def audit_formula_name
    return unless @strict
    # skip for non-official taps
    return if formula.tap.nil? || !formula.tap.official?

    name = formula.name
    full_name = formula.full_name

    if Homebrew::MissingFormula.blacklisted_reason(name)
      problem "'#{name}' is blacklisted."
    end

    if Formula.aliases.include? name
      problem "Formula name conflicts with existing aliases."
      return
    end

    if oldname = CoreTap.instance.formula_renames[name]
      problem "'#{name}' is reserved as the old name of #{oldname}"
      return
    end

    if !formula.core_formula? && Formula.core_names.include?(name)
      problem "Formula name conflicts with existing core formula."
      return
    end

    @@local_official_taps_name_map ||= Tap.select(&:official?).flat_map(&:formula_names)
                                          .each_with_object({}) do |tap_formula_full_name, name_map|
      tap_formula_name = tap_formula_full_name.split("/").last
      name_map[tap_formula_name] ||= []
      name_map[tap_formula_name] << tap_formula_full_name
      name_map
    end

    same_name_tap_formulae = @@local_official_taps_name_map[name] || []

    if @online
      Homebrew.search_taps(name).each do |tap_formula_full_name|
        tap_formula_name = tap_formula_full_name.split("/").last
        next if tap_formula_name != name
        same_name_tap_formulae << tap_formula_full_name
      end
    end

    same_name_tap_formulae.delete(full_name)

    return if same_name_tap_formulae.empty?
    problem "Formula name conflicts with #{same_name_tap_formulae.join ", "}"
  end

  def audit_deps
    @specs.each do |spec|
      # Check for things we don't like to depend on.
      # We allow non-Homebrew installs whenever possible.
      spec.deps.each do |dep|
        begin
          dep_f = dep.to_formula
        rescue TapFormulaUnavailableError
          # Don't complain about missing cross-tap dependencies
          next
        rescue FormulaUnavailableError
          problem "Can't find dependency #{dep.name.inspect}."
          next
        rescue TapFormulaAmbiguityError
          problem "Ambiguous dependency #{dep.name.inspect}."
          next
        rescue TapFormulaWithOldnameAmbiguityError
          problem "Ambiguous oldname dependency #{dep.name.inspect}."
          next
        end

        if dep_f.oldname && dep.name.split("/").last == dep_f.oldname
          problem "Dependency '#{dep.name}' was renamed; use new name '#{dep_f.name}'."
        end

        if @@aliases.include?(dep.name) &&
           (dep_f.core_formula? || !dep_f.versioned_formula?)
          problem "Dependency '#{dep.name}' is an alias; use the canonical name '#{dep.to_formula.full_name}'."
        end

        if @new_formula && dep_f.keg_only_reason &&
           !["openssl", "apr", "apr-util"].include?(dep.name) &&
           [:provided_by_macos, :provided_by_osx].include?(dep_f.keg_only_reason.reason)
          problem "Dependency '#{dep.name}' may be unnecessary as it is provided by macOS; try to build this formula without it."
        end

        dep.options.reject do |opt|
          next true if dep_f.option_defined?(opt)
          dep_f.requirements.detect do |r|
            if r.recommended?
              opt.name == "with-#{r.name}"
            elsif r.optional?
              opt.name == "without-#{r.name}"
            end
          end
        end.each do |opt|
          problem "Dependency #{dep} does not define option #{opt.name.inspect}"
        end

        case dep.name
        when "git"
          problem "Don't use git as a dependency"
        when "mercurial"
          problem "Use `depends_on :hg` instead of `depends_on 'mercurial'`"
        when "gfortran"
          problem "Use `depends_on :fortran` instead of `depends_on 'gfortran'`"
        when "ruby"
          problem <<-EOS.undent
            Don't use "ruby" as a dependency. If this formula requires a
            minimum Ruby version not provided by the system you should
            use the RubyRequirement:
              depends_on :ruby => "1.8"
            where "1.8" is the minimum version of Ruby required.
          EOS
        when "open-mpi", "mpich"
          problem <<-EOS.undent
            There are multiple conflicting ways to install MPI. Use an MPIRequirement:
              depends_on :mpi => [<lang list>]
            Where <lang list> is a comma delimited list that can include:
              :cc, :cxx, :f77, :f90
            EOS
        when *BUILD_TIME_DEPS
          next if dep.build? || dep.run?
          problem <<-EOS.undent
            #{dep} dependency should be
              depends_on "#{dep}" => :build
            Or if it is indeed a runtime dependency
              depends_on "#{dep}" => :run
          EOS
        end
      end
    end
  end

  def audit_conflicts
    formula.conflicts.each do |c|
      begin
        Formulary.factory(c.name)
      rescue TapFormulaUnavailableError
        # Don't complain about missing cross-tap conflicts.
        next
      rescue FormulaUnavailableError
        problem "Can't find conflicting formula #{c.name.inspect}."
      rescue TapFormulaAmbiguityError, TapFormulaWithOldnameAmbiguityError
        problem "Ambiguous conflicting formula #{c.name.inspect}."
      end
    end

    versioned_conflicts_whitelist = %w[node@ bash-completion@].freeze

    return unless formula.conflicts.any? && formula.versioned_formula?
    return if formula.name.start_with?(*versioned_conflicts_whitelist)
    problem <<-EOS
      Versioned formulae should not use `conflicts_with`.
      Use `keg_only :versioned_formula` instead.
    EOS
  end

  def audit_keg_only_style
    return unless @strict
    return unless formula.keg_only?

    whitelist = %w[
      Apple
      macOS
      OS
      Homebrew
      Xcode
      GPG
      GNOME
      BSD
      Firefox
    ].freeze

    reason = formula.keg_only_reason.to_s
    # Formulae names can legitimately be uppercase/lowercase/both.
    name = Regexp.new(formula.name, Regexp::IGNORECASE)
    reason.sub!(name, "")
    first_word = reason.split[0]

    if reason =~ /\A[A-Z]/ && !reason.start_with?(*whitelist)
      problem <<-EOS.undent
        '#{first_word}' from the keg_only reason should be '#{first_word.downcase}'.
      EOS
    end

    return unless reason.end_with?(".")
    problem "keg_only reason should not end with a period."
  end

  def audit_options
    formula.options.each do |o|
      if o.name == "32-bit"
        problem "macOS has been 64-bit only since 10.6 so 32-bit options are deprecated."
      end

      next unless @strict

      if o.name == "universal"
        problem "macOS has been 64-bit only since 10.6 so universal options are deprecated."
      end

      if o.name !~ /with(out)?-/ && o.name != "c++11" && o.name != "universal"
        problem "Options should begin with with/without. Migrate '--#{o.name}' with `deprecated_option`."
      end

      next unless o.name =~ /^with(out)?-(?:checks?|tests)$/
      unless formula.deps.any? { |d| d.name == "check" && (d.optional? || d.recommended?) }
        problem "Use '--with#{$1}-test' instead of '--#{o.name}'. Migrate '--#{o.name}' with `deprecated_option`."
      end
    end

    return unless @new_formula
    return if formula.deprecated_options.empty?
    return if formula.versioned_formula?
    problem "New formulae should not use `deprecated_option`."
  end

  def audit_homepage
    homepage = formula.homepage

    if homepage.nil? || homepage.empty?
      return
    end

    return unless @online

    return unless DevelopmentTools.curl_handles_most_https_homepages?
    if http_content_problem = FormulaAuditor.check_http_content(homepage,
                                             user_agents: [:browser, :default])
      problem http_content_problem
    end
  end

  def audit_bottle_spec
    return unless formula.bottle_disabled?
    return if formula.bottle_disable_reason.valid?
    problem "Unrecognized bottle modifier"
  end

  def audit_github_repository
    return unless @online
    return unless @new_formula

    regex = %r{https?://github\.com/([^/]+)/([^/]+)/?.*}
    _, user, repo = *regex.match(formula.stable.url) if formula.stable
    _, user, repo = *regex.match(formula.homepage) unless user
    return if !user || !repo

    repo.gsub!(/.git$/, "")

    begin
      metadata = GitHub.repository(user, repo)
    rescue GitHub::HTTPNotFoundError
      return
    end

    return if metadata.nil?

    problem "GitHub fork (not canonical repository)" if metadata["fork"]
    if (metadata["forks_count"] < 20) && (metadata["subscribers_count"] < 20) &&
       (metadata["stargazers_count"] < 50)
      problem "GitHub repository not notable enough (<20 forks, <20 watchers and <50 stars)"
    end

    return if Date.parse(metadata["created_at"]) <= (Date.today - 30)
    problem "GitHub repository too new (<30 days old)"
  end

  def audit_specs
    if head_only?(formula) && formula.tap.to_s.downcase !~ %r{[-/]head-only$}
      problem "Head-only (no stable download)"
    end

    if devel_only?(formula) && formula.tap.to_s.downcase !~ %r{[-/]devel-only$}
      problem "Devel-only (no stable download)"
    end

    %w[Stable Devel HEAD].each do |name|
      next unless spec = formula.send(name.downcase)

      ra = ResourceAuditor.new(spec, online: @online, strict: @strict).audit
      problems.concat ra.problems.map { |problem| "#{name}: #{problem}" }

      spec.resources.each_value do |resource|
        ra = ResourceAuditor.new(resource, online: @online, strict: @strict).audit
        problems.concat ra.problems.map { |problem|
          "#{name} resource #{resource.name.inspect}: #{problem}"
        }
      end

      next if spec.patches.empty?
      spec.patches.each { |p| patch_problems(p) if p.external? }
      next unless @new_formula
      problem "New formulae should not require patches to build. Patches should be submitted and accepted upstream first."
    end

    %w[Stable Devel].each do |name|
      next unless spec = formula.send(name.downcase)
      version = spec.version
      if version.to_s !~ /\d/
        problem "#{name}: version (#{version}) is set to a string without a digit"
      end
      if version.to_s.start_with?("HEAD")
        problem "#{name}: non-HEAD version name (#{version}) should not begin with HEAD"
      end
    end

    if formula.stable && formula.devel
      if formula.devel.version < formula.stable.version
        problem "devel version #{formula.devel.version} is older than stable version #{formula.stable.version}"
      elsif formula.devel.version == formula.stable.version
        problem "stable and devel versions are identical"
      end
    end

    unstable_whitelist = %w[
      aalib 1.4rc5
      angolmois 2.0.0alpha2
      automysqlbackup 3.0-rc6
      aview 1.3.0rc1
      distcc 3.2rc1
      elm-format 0.6.0-alpha
      ftgl 2.1.3-rc5
      hidapi 0.8.0-rc1
      libcaca 0.99b19
      nethack4 4.3.0-beta2
      opensyobon 1.0rc2
      premake 4.4-beta5
      pwnat 0.3-beta
      pxz 4.999.9
      recode 3.7-beta2
      speexdsp 1.2rc3
      sqoop 1.4.6
      tcptraceroute 1.5beta7
      testssl 2.8rc3
      tiny-fugue 5.0b8
      vbindiff 3.0_beta4
    ].each_slice(2).to_a.map do |formula, version|
      [formula, version.sub(/\d+$/, "")]
    end

    gnome_devel_whitelist = %w[
      gtk-doc 1.25
      libart 2.3.21
      pygtkglext 1.1.0
    ].each_slice(2).to_a.map do |formula, version|
      [formula, version.split(".")[0..1].join(".")]
    end

    stable = formula.stable
    case stable && stable.url
    when /[\d\._-](alpha|beta|rc\d)/
      matched = $1
      version_prefix = stable.version.to_s.sub(/\d+$/, "")
      return if unstable_whitelist.include?([formula.name, version_prefix])
      problem "Stable version URLs should not contain #{matched}"
    when %r{download\.gnome\.org/sources}, %r{ftp\.gnome\.org/pub/GNOME/sources}i
      version_prefix = stable.version.to_s.split(".")[0..1].join(".")
      return if gnome_devel_whitelist.include?([formula.name, version_prefix])
      version = Version.parse(stable.url)
      if version >= Version.create("1.0")
        minor_version = version.to_s.split(".", 3)[1].to_i
        if minor_version.odd?
          problem "#{stable.version} is a development release"
        end
      end
    end
  end

  def audit_revision_and_version_scheme
    return unless formula.tap # skip formula not from core or any taps
    return unless formula.tap.git? # git log is required
    return if @new_formula

    fv = FormulaVersions.new(formula)
    attributes = [:revision, :version_scheme]
    attributes_map = fv.version_attributes_map(attributes, "origin/master")

    current_version_scheme = formula.version_scheme
    [:stable, :devel].each do |spec|
      spec_version_scheme_map = attributes_map[:version_scheme][spec]
      next if spec_version_scheme_map.empty?

      version_schemes = spec_version_scheme_map.values.flatten
      max_version_scheme = version_schemes.max
      max_version = spec_version_scheme_map.select do |_, version_scheme|
        version_scheme.first == max_version_scheme
      end.keys.max

      if max_version_scheme && current_version_scheme < max_version_scheme
        problem "version_scheme should not decrease (from #{max_version_scheme} to #{current_version_scheme})"
      end

      if max_version_scheme && current_version_scheme >= max_version_scheme &&
         current_version_scheme > 1 &&
         !version_schemes.include?(current_version_scheme - 1)
        problem "version_schemes should only increment by 1"
      end

      formula_spec = formula.send(spec)
      next unless formula_spec

      spec_version = formula_spec.version
      next unless max_version
      next if spec_version >= max_version

      above_max_version_scheme = current_version_scheme > max_version_scheme
      map_includes_version = spec_version_scheme_map.keys.include?(spec_version)
      next if !current_version_scheme.zero? &&
              (above_max_version_scheme || map_includes_version)
      problem "#{spec} version should not decrease (from #{max_version} to #{spec_version})"
    end

    current_revision = formula.revision
    revision_map = attributes_map[:revision][:stable]
    if formula.stable && !revision_map.empty?
      stable_revisions = revision_map[formula.stable.version]
      stable_revisions ||= []
      max_revision = stable_revisions.max || 0

      if current_revision < max_revision
        problem "revision should not decrease (from #{max_revision} to #{current_revision})"
      end

      stable_revisions -= [formula.revision]
      if !current_revision.zero? && stable_revisions.empty? &&
         revision_map.keys.length > 1
        problem "'revision #{formula.revision}' should be removed"
      elsif current_revision > 1 &&
            current_revision != max_revision &&
            !stable_revisions.include?(current_revision - 1)
        problem "revisions should only increment by 1"
      end
    elsif !current_revision.zero? # head/devel-only formula
      problem "'revision #{current_revision}' should be removed"
    end
  end

  def audit_legacy_patches
    return unless formula.respond_to?(:patches)
    legacy_patches = Patch.normalize_legacy_patches(formula.patches).grep(LegacyPatch)

    return if legacy_patches.empty?

    problem "Use the patch DSL instead of defining a 'patches' method"
    legacy_patches.each { |p| patch_problems(p) }
  end

  def patch_problems(patch)
    case patch.url
    when /raw\.github\.com/, %r{gist\.github\.com/raw}, %r{gist\.github\.com/.+/raw},
      %r{gist\.githubusercontent\.com/.+/raw}
      unless patch.url =~ /[a-fA-F0-9]{40}/
        problem "GitHub/Gist patches should specify a revision:\n#{patch.url}"
      end
    when %r{https?://patch-diff\.githubusercontent\.com/raw/(.+)/(.+)/pull/(.+)\.(?:diff|patch)}
      problem <<-EOS.undent
        use GitHub pull request URLs:
          https://github.com/#{$1}/#{$2}/pull/#{$3}.patch
        Rather than patch-diff:
          #{patch.url}
      EOS
    when %r{macports/trunk}
      problem "MacPorts patches should specify a revision instead of trunk:\n#{patch.url}"
    when %r{^http://trac\.macports\.org}
      problem "Patches from MacPorts Trac should be https://, not http:\n#{patch.url}"
    when %r{^http://bugs\.debian\.org}
      problem "Patches from Debian should be https://, not http:\n#{patch.url}"
    end
  end

  def audit_text
    if text =~ /system\s+['"]scons/
      problem "use \"scons *args\" instead of \"system 'scons', *args\""
    end

    if text =~ /system\s+['"]xcodebuild/
      problem %q(use "xcodebuild *args" instead of "system 'xcodebuild', *args")
    end

    bin_names = Set.new
    bin_names << formula.name
    bin_names += formula.aliases
    [formula.bin, formula.sbin].each do |dir|
      next unless dir.exist?
      bin_names += dir.children.map(&:basename).map(&:to_s)
    end
    bin_names.each do |name|
      ["system", "shell_output", "pipe_output"].each do |cmd|
        if text =~ %r{(def test|test do).*(#{Regexp.escape(HOMEBREW_PREFIX)}/bin/)?#{cmd}[\(\s]+['"]#{Regexp.escape(name)}[\s'"]}m
          problem %Q(fully scope test #{cmd} calls e.g. #{cmd} "\#{bin}/#{name}")
        end
      end
    end

    if text =~ /xcodebuild[ (]*["'*]*/ && !text.include?("SYMROOT=")
      problem 'xcodebuild should be passed an explicit "SYMROOT"'
    end

    if text.include? "Formula.factory("
      problem "\"Formula.factory(name)\" is deprecated in favor of \"Formula[name]\""
    end

    if text.include?("def plist") && !text.include?("plist_options")
      problem "Please set plist_options when using a formula-defined plist."
    end

    if text =~ /depends_on\s+['"]openssl['"]/ && text =~ /depends_on\s+['"]libressl['"]/
      problem "Formulae should not depend on both OpenSSL and LibreSSL (even optionally)."
    end

    if text =~ /virtualenv_(create|install_with_resources)/ &&
       text =~ /resource\s+['"]setuptools['"]\s+do/
      problem "Formulae using virtualenvs do not need a `setuptools` resource."
    end

    if text =~ /system\s+['"]go['"],\s+['"]get['"]/
      problem "Formulae should not use `go get`. If non-vendored resources are required use `go_resource`s."
    end

    return unless text.include?('require "language/go"') && !text.include?("go_resource")
    problem "require \"language/go\" is unnecessary unless using `go_resource`s"
  end

  def audit_lines
    text.without_patch.split("\n").each_with_index do |line, lineno|
      line_problems(line, lineno+1)
    end
  end

  def line_problems(line, _lineno)
    if line =~ /<(Formula|AmazonWebServicesFormula|ScriptFileFormula|GithubGistFormula)/
      problem "Use a space in class inheritance: class Foo < #{$1}"
    end

    # Commented-out cmake support from default template
    problem "Commented cmake call found" if line.include?('# system "cmake')

    # Comments from default template
    [
      "# PLEASE REMOVE",
      "# Documentation:",
      "# if this fails, try separate make/make install steps",
      "# The URL of the archive",
      "## Naming --",
      "# if your formula requires any X11/XQuartz components",
      "# if your formula fails when building in parallel",
      "# Remove unrecognized options if warned by configure",
    ].each do |comment|
      next unless line.include?(comment)
      problem "Please remove default template comments"
    end

    # FileUtils is included in Formula
    # encfs modifies a file with this name, so check for some leading characters
    if line =~ %r{[^'"/]FileUtils\.(\w+)}
      problem "Don't need 'FileUtils.' before #{$1}."
    end

    # Check for long inreplace block vars
    if line =~ /inreplace .* do \|(.{2,})\|/
      problem "\"inreplace <filenames> do |s|\" is preferred over \"|#{$1}|\"."
    end

    # Check for string interpolation of single values.
    if line =~ /(system|inreplace|gsub!|change_make_var!).*[ ,]"#\{([\w.]+)\}"/
      problem "Don't need to interpolate \"#{$2}\" with #{$1}"
    end

    # Check for string concatenation; prefer interpolation
    if line =~ /(#\{\w+\s*\+\s*['"][^}]+\})/
      problem "Try not to concatenate paths in string interpolation:\n   #{$1}"
    end

    # Prefer formula path shortcuts in Pathname+
    if line =~ %r{\(\s*(prefix\s*\+\s*(['"])(bin|include|libexec|lib|sbin|share|Frameworks)[/'"])}
      problem "\"(#{$1}...#{$2})\" should be \"(#{$3.downcase}+...)\""
    end

    if line =~ /((man)\s*\+\s*(['"])(man[1-8])(['"]))/
      problem "\"#{$1}\" should be \"#{$4}\""
    end

    # Prefer formula path shortcuts in strings
    if line =~ %r[(\#\{prefix\}/(bin|include|libexec|lib|sbin|share|Frameworks))]
      problem "\"#{$1}\" should be \"\#{#{$2.downcase}}\""
    end

    if line =~ %r[((\#\{prefix\}/share/man/|\#\{man\}/)(man[1-8]))]
      problem "\"#{$1}\" should be \"\#{#{$3}}\""
    end

    if line =~ %r[((\#\{share\}/(man)))[/'"]]
      problem "\"#{$1}\" should be \"\#{#{$3}}\""
    end

    if line =~ %r[(\#\{prefix\}/share/(info|man))]
      problem "\"#{$1}\" should be \"\#{#{$2}}\""
    end

    if line =~ /depends_on :(automake|autoconf|libtool)/
      problem ":#{$1} is deprecated. Usage should be \"#{$1}\""
    end

    if line =~ /depends_on :apr/
      problem ":apr is deprecated. Usage should be \"apr-util\""
    end

    if line =~ /depends_on :tex/
      problem ":tex is deprecated"
    end

    if line =~ /depends_on\s+['"](.+)['"]\s+=>\s+:(lua|perl|python|ruby)(\d*)/
      problem "#{$2} modules should be vendored rather than use deprecated `depends_on \"#{$1}\" => :#{$2}#{$3}`"
    end

    if line =~ /depends_on\s+['"](.+)['"]\s+=>\s+(.*)/
      dep = $1
      $2.split(" ").map do |o|
        next unless o =~ /^\[?['"](.*)['"]/
        problem "Dependency #{dep} should not use option #{$1}"
      end
    end

    # Commented-out depends_on
    problem "Commented-out dep #{$1}" if line =~ /#\s*depends_on\s+(.+)\s*$/

    if line =~ /if\s+ARGV\.include\?\s+'--(HEAD|devel)'/
      problem "Use \"if build.#{$1.downcase}?\" instead"
    end

    problem "Use separate make calls" if line.include?("make && make")

    problem "Use spaces instead of tabs for indentation" if line =~ /^[ ]*\t/

    if line.include?("ENV.x11")
      problem "Use \"depends_on :x11\" instead of \"ENV.x11\""
    end

    # Avoid hard-coding compilers
    if line =~ %r{(system|ENV\[.+\]\s?=)\s?['"](/usr/bin/)?(gcc|llvm-gcc|clang)['" ]}
      problem "Use \"\#{ENV.cc}\" instead of hard-coding \"#{$3}\""
    end

    if line =~ %r{(system|ENV\[.+\]\s?=)\s?['"](/usr/bin/)?((g|llvm-g|clang)\+\+)['" ]}
      problem "Use \"\#{ENV.cxx}\" instead of hard-coding \"#{$3}\""
    end

    if line =~ /system\s+['"](env|export)(\s+|['"])/
      problem "Use ENV instead of invoking '#{$1}' to modify the environment"
    end

    if formula.name != "wine" && line =~ /ENV\.universal_binary/
      problem "macOS has been 64-bit only since 10.6 so ENV.universal_binary is deprecated."
    end

    if line =~ /build\.universal\?/
      problem "macOS has been 64-bit only so build.universal? is deprecated."
    end

    if line =~ /version == ['"]HEAD['"]/
      problem "Use 'build.head?' instead of inspecting 'version'"
    end

    if line =~ /build\.include\?[\s\(]+['"]\-\-(.*)['"]/
      problem "Reference '#{$1}' without dashes"
    end

    if line =~ /build\.include\?[\s\(]+['"]with(out)?-(.*)['"]/
      problem "Use build.with#{$1}? \"#{$2}\" instead of build.include? 'with#{$1}-#{$2}'"
    end

    if line =~ /build\.with\?[\s\(]+['"]-?-?with-(.*)['"]/
      problem "Don't duplicate 'with': Use `build.with? \"#{$1}\"` to check for \"--with-#{$1}\""
    end

    if line =~ /build\.without\?[\s\(]+['"]-?-?without-(.*)['"]/
      problem "Don't duplicate 'without': Use `build.without? \"#{$1}\"` to check for \"--without-#{$1}\""
    end

    if line =~ /unless build\.with\?(.*)/
      problem "Use if build.without?#{$1} instead of unless build.with?#{$1}"
    end

    if line =~ /unless build\.without\?(.*)/
      problem "Use if build.with?#{$1} instead of unless build.without?#{$1}"
    end

    if line =~ /(not\s|!)\s*build\.with?\?/
      problem "Don't negate 'build.with?': use 'build.without?'"
    end

    if line =~ /(not\s|!)\s*build\.without?\?/
      problem "Don't negate 'build.without?': use 'build.with?'"
    end

    if line =~ /ARGV\.(?!(debug\?|verbose\?|value[\(\s]))/
      problem "Use build instead of ARGV to check options"
    end

    problem "Use new-style option definitions" if line.include?("def options")

    if line.end_with?("def test")
      problem "Use new-style test definitions (test do)"
    end

    if line.include?("MACOS_VERSION")
      problem "Use MacOS.version instead of MACOS_VERSION"
    end

    if line.include?("MACOS_FULL_VERSION")
      problem "Use MacOS.full_version instead of MACOS_FULL_VERSION"
    end

    cats = %w[leopard snow_leopard lion mountain_lion].join("|")
    if line =~ /MacOS\.(?:#{cats})\?/
      problem "\"#{$&}\" is deprecated, use a comparison to MacOS.version instead"
    end

    if line =~ /skip_clean\s+:all/
      problem "`skip_clean :all` is deprecated; brew no longer strips symbols\n" \
              "\tPass explicit paths to prevent Homebrew from removing empty folders."
    end

    if line =~ /depends_on [A-Z][\w:]+\.new$/
      problem "`depends_on` can take requirement classes instead of instances"
    end

    if line =~ /^def (\w+).*$/
      problem "Define method #{$1.inspect} in the class body, not at the top-level"
    end

    if line.include?("ENV.fortran") && !formula.requirements.map(&:class).include?(FortranRequirement)
      problem "Use `depends_on :fortran` instead of `ENV.fortran`"
    end

    if line =~ /JAVA_HOME/i && !formula.requirements.map(&:class).include?(JavaRequirement)
      problem "Use `depends_on :java` to set JAVA_HOME"
    end

    if line =~ /depends_on :(.+) (if.+|unless.+)$/
      conditional_dep_problems($1.to_sym, $2, $&)
    end

    if line =~ /depends_on ['"](.+)['"] (if.+|unless.+)$/
      conditional_dep_problems($1, $2, $&)
    end

    if line =~ /(Dir\[("[^\*{},]+")\])/
      problem "#{$1} is unnecessary; just use #{$2}"
    end

    if line =~ /system (["'](#{FILEUTILS_METHODS})["' ])/o
      system = $1
      method = $2
      problem "Use the `#{method}` Ruby method instead of `system #{system}`"
    end

    if line =~ /assert [^!]+\.include?/
      problem "Use `assert_match` instead of `assert ...include?`"
    end

    if line.include?('system "npm", "install"') && !line.include?("Language::Node") &&
       formula.name !~ /^kibana(\@\d+(\.\d+)?)?$/
      problem "Use Language::Node for npm install args"
    end

    if line.include?("fails_with :llvm")
      problem "'fails_with :llvm' is now a no-op so should be removed"
    end

    if line =~ /system\s+['"](otool|install_name_tool|lipo)/ && formula.name != "cctools"
      problem "Use ruby-macho instead of calling #{$1}"
    end

    if formula.tap.to_s == "homebrew/core"
      ["OS.mac?", "OS.linux?"].each do |check|
        next unless line.include?(check)
        problem "Don't use #{check}; Homebrew/core only supports macOS"
      end
    end

    if line =~ /((revision|version_scheme)\s+0)/
      problem "'#{$1}' should be removed"
    end

    return unless @strict

    problem "`#{$1}` in formulae is deprecated" if line =~ /(env :(std|userpaths))/

    if line =~ /system ((["'])[^"' ]*(?:\s[^"' ]*)+\2)/
      bad_system = $1
      unless %w[| < > & ; *].any? { |c| bad_system.include? c }
        good_system = bad_system.gsub(" ", "\", \"")
        problem "Use `system #{good_system}` instead of `system #{bad_system}` "
      end
    end

    problem "`#{$1}` is now unnecessary" if line =~ /(require ["']formula["'])/

    if line =~ %r{#\{share\}/#{Regexp.escape(formula.name)}[/'"]}
      problem "Use \#{pkgshare} instead of \#{share}/#{formula.name}"
    end

    return unless line =~ %r{share(\s*[/+]\s*)(['"])#{Regexp.escape(formula.name)}(?:\2|/)}
    problem "Use pkgshare instead of (share#{$1}\"#{formula.name}\")"
  end

  def audit_caveats
    return unless formula.caveats.to_s.include?("setuid")
    problem "Don't recommend setuid in the caveats, suggest sudo instead."
  end

  def audit_reverse_migration
    # Only enforce for new formula being re-added to core and official taps
    return unless @strict
    return unless formula.tap && formula.tap.official?
    return unless formula.tap.tap_migrations.key?(formula.name)

    problem <<-EOS.undent
      #{formula.name} seems to be listed in tap_migrations.json!
      Please remove #{formula.name} from present tap & tap_migrations.json
      before submitting it to Homebrew/homebrew-#{formula.tap.repo}.
    EOS
  end

  def audit_prefix_has_contents
    return unless formula.prefix.directory?
    return unless Keg.new(formula.prefix).empty_installation?

    problem <<-EOS.undent
      The installation seems to be empty. Please ensure the prefix
      is set correctly and expected files are installed.
      The prefix configure/make argument may be case-sensitive.
    EOS
  end

  def conditional_dep_problems(dep, condition, line)
    quoted_dep = quote_dep(dep)
    dep = Regexp.escape(dep.to_s)

    case condition
    when /if build\.include\? ['"]with-#{dep}['"]$/, /if build\.with\? ['"]#{dep}['"]$/
      problem %Q(Replace #{line.inspect} with "depends_on #{quoted_dep} => :optional")
    when /unless build\.include\? ['"]without-#{dep}['"]$/, /unless build\.without\? ['"]#{dep}['"]$/
      problem %Q(Replace #{line.inspect} with "depends_on #{quoted_dep} => :recommended")
    end
  end

  def quote_dep(dep)
    dep.is_a?(Symbol) ? dep.inspect : "'#{dep}'"
  end

  def problem_if_output(output)
    problem(output) if output
  end

  def audit
    only_audits = ARGV.value("only").to_s.split(",")
    except_audits = ARGV.value("except").to_s.split(",")
    if !only_audits.empty? && !except_audits.empty?
      odie "--only and --except cannot be used simultaneously!"
    end

    methods.map(&:to_s).grep(/^audit_/).each do |audit_method_name|
      name = audit_method_name.gsub(/^audit_/, "")
      if !only_audits.empty?
        next unless only_audits.include?(name)
      elsif !except_audits.empty?
        next if except_audits.include?(name)
      end
      send(audit_method_name)
    end
  end

  private

  def problem(p)
    @problems << p
  end

  def head_only?(formula)
    formula.head && formula.devel.nil? && formula.stable.nil?
  end

  def devel_only?(formula)
    formula.devel && formula.stable.nil?
  end
end

class ResourceAuditor
  attr_reader :problems
  attr_reader :version, :checksum, :using, :specs, :url, :mirrors, :name

  def initialize(resource, options = {})
    @name     = resource.name
    @version  = resource.version
    @checksum = resource.checksum
    @url      = resource.url
    @mirrors  = resource.mirrors
    @using    = resource.using
    @specs    = resource.specs
    @online   = options[:online]
    @strict   = options[:strict]
    @problems = []
  end

  def audit
    audit_version
    audit_checksum
    audit_download_strategy
    audit_urls
    self
  end

  def audit_version
    if version.nil?
      problem "missing version"
    elsif version.to_s.empty?
      problem "version is set to an empty string"
    elsif !version.detected_from_url?
      version_text = version
      version_url = Version.detect(url, specs)
      if version_url.to_s == version_text.to_s && version.instance_of?(Version)
        problem "version #{version_text} is redundant with version scanned from URL"
      end
    end

    if version.to_s.start_with?("v")
      problem "version #{version} should not have a leading 'v'"
    end

    return unless version.to_s =~ /_\d+$/
    problem "version #{version} should not end with an underline and a number"
  end

  def audit_checksum
    return unless checksum

    case checksum.hash_type
    when :md5
      problem "MD5 checksums are deprecated, please use SHA256"
      return
    when :sha1
      problem "SHA1 checksums are deprecated, please use SHA256"
      return
    when :sha256 then len = 64
    end

    if checksum.empty?
      problem "#{checksum.hash_type} is empty"
    else
      problem "#{checksum.hash_type} should be #{len} characters" unless checksum.hexdigest.length == len
      problem "#{checksum.hash_type} contains invalid characters" unless checksum.hexdigest =~ /^[a-fA-F0-9]+$/
      problem "#{checksum.hash_type} should be lowercase" unless checksum.hexdigest == checksum.hexdigest.downcase
    end
  end

  def audit_download_strategy
    if url =~ %r{^(cvs|bzr|hg|fossil)://} || url =~ %r{^(svn)\+http://}
      problem "Use of the #{$&} scheme is deprecated, pass `:using => :#{$1}` instead"
    end

    url_strategy = DownloadStrategyDetector.detect(url)

    if using == :git || url_strategy == GitDownloadStrategy
      if specs[:tag] && !specs[:revision]
        problem "Git should specify :revision when a :tag is specified."
      end
    end

    return unless using

    if using == :ssl3 || \
       (Object.const_defined?("CurlSSL3DownloadStrategy") && using == CurlSSL3DownloadStrategy)
      problem "The SSL3 download strategy is deprecated, please choose a different URL"
    elsif (Object.const_defined?("CurlUnsafeDownloadStrategy") && using == CurlUnsafeDownloadStrategy) || \
          (Object.const_defined?("UnsafeSubversionDownloadStrategy") && using == UnsafeSubversionDownloadStrategy)
      problem "#{using.name} is deprecated, please choose a different URL"
    end

    if using == :cvs
      mod = specs[:module]

      problem "Redundant :module value in URL" if mod == name

      if url =~ %r{:[^/]+$}
        mod = url.split(":").last

        if mod == name
          problem "Redundant CVS module appended to URL"
        else
          problem "Specify CVS module as `:module => \"#{mod}\"` instead of appending it to the URL"
        end
      end
    end

    return unless url_strategy == DownloadStrategyDetector.detect("", using)
    problem "Redundant :using value in URL"
  end

  def audit_urls
    # Check GNU urls; doesn't apply to mirrors
    if url =~ %r{^(?:https?|ftp)://ftpmirror.gnu.org/(.*)}
      problem "Please use \"https://ftp.gnu.org/gnu/#{$1}\" instead of #{url}."
    end

    if mirrors.include?(url)
      problem "URL should not be duplicated as a mirror: #{url}"
    end

    urls = [url] + mirrors

    # Check a variety of SSL/TLS URLs that don't consistently auto-redirect
    # or are overly common errors that need to be reduced & fixed over time.
    urls.each do |p|
      case p
      when %r{^http://ftp\.gnu\.org/},
           %r{^http://ftpmirror\.gnu\.org/},
           %r{^http://download\.savannah\.gnu\.org/},
           %r{^http://download-mirror\.savannah\.gnu\.org/},
           %r{^http://[^/]*\.apache\.org/},
           %r{^http://code\.google\.com/},
           %r{^http://fossies\.org/},
           %r{^http://mirrors\.kernel\.org/},
           %r{^http://(?:[^/]*\.)?bintray\.com/},
           %r{^http://tools\.ietf\.org/},
           %r{^http://launchpad\.net/},
           %r{^http://github\.com/},
           %r{^http://bitbucket\.org/},
           %r{^http://anonscm\.debian\.org/},
           %r{^http://cpan\.metacpan\.org/},
           %r{^http://hackage\.haskell\.org/},
           %r{^http://(?:[^/]*\.)?archive\.org},
           %r{^http://(?:[^/]*\.)?freedesktop\.org},
           %r{^http://(?:[^/]*\.)?mirrorservice\.org/}
        problem "Please use https:// for #{p}"
      when %r{^http://search\.mcpan\.org/CPAN/(.*)}i
        problem "#{p} should be `https://cpan.metacpan.org/#{$1}`"
      when %r{^(http|ftp)://ftp\.gnome\.org/pub/gnome/(.*)}i
        problem "#{p} should be `https://download.gnome.org/#{$2}`"
      when %r{^git://anonscm\.debian\.org/users/(.*)}i
        problem "#{p} should be `https://anonscm.debian.org/git/users/#{$1}`"
      end
    end

    # Prefer HTTP/S when possible over FTP protocol due to possible firewalls.
    urls.each do |p|
      case p
      when %r{^ftp://ftp\.mirrorservice\.org}
        problem "Please use https:// for #{p}"
      when %r{^ftp://ftp\.cpan\.org/pub/CPAN(.*)}i
        problem "#{p} should be `http://search.cpan.org/CPAN#{$1}`"
      end
    end

    # Check SourceForge urls
    urls.each do |p|
      # Skip if the URL looks like a SVN repo
      next if p.include? "/svnroot/"
      next if p.include? "svn.sourceforge"

      # Is it a sourceforge http(s) URL?
      next unless p =~ %r{^https?://.*\b(sourceforge|sf)\.(com|net)}

      if p =~ /(\?|&)use_mirror=/
        problem "Don't use #{$1}use_mirror in SourceForge urls (url is #{p})."
      end

      if p.end_with?("/download")
        problem "Don't use /download in SourceForge urls (url is #{p})."
      end

      if p =~ %r{^https?://sourceforge\.}
        problem "Use https://downloads.sourceforge.net to get geolocation (url is #{p})."
      end

      if p =~ %r{^https?://prdownloads\.}
        problem "Don't use prdownloads in SourceForge urls (url is #{p}).\n" \
                "\tSee: http://librelist.com/browser/homebrew/2011/1/12/prdownloads-is-bad/"
      end

      if p =~ %r{^http://\w+\.dl\.}
        problem "Don't use specific dl mirrors in SourceForge urls (url is #{p})."
      end

      problem "Please use https:// for #{p}" if p.start_with? "http://downloads"
    end

    # Debian has an abundance of secure mirrors. Let's not pluck the insecure
    # one out of the grab bag.
    urls.each do |u|
      next unless u =~ %r{^http://http\.debian\.net/debian/(.*)}i
      problem <<-EOS.undent
        Please use a secure mirror for Debian URLs.
        We recommend:
          https://mirrors.ocf.berkeley.edu/debian/#{$1}
      EOS
    end

    # Check for Google Code download urls, https:// is preferred
    # Intentionally not extending this to SVN repositories due to certificate
    # issues.
    urls.grep(%r{^http://.*\.googlecode\.com/files.*}) do |u|
      problem "Please use https:// for #{u}"
    end

    # Check for new-url Google Code download urls, https:// is preferred
    urls.grep(%r{^http://code\.google\.com/}) do |u|
      problem "Please use https:// for #{u}"
    end

    # Check for git:// GitHub repo urls, https:// is preferred.
    urls.grep(%r{^git://[^/]*github\.com/}) do |u|
      problem "Please use https:// for #{u}"
    end

    # Check for git:// Gitorious repo urls, https:// is preferred.
    urls.grep(%r{^git://[^/]*gitorious\.org/}) do |u|
      problem "Please use https:// for #{u}"
    end

    # Check for http:// GitHub repo urls, https:// is preferred.
    urls.grep(%r{^http://github\.com/.*\.git$}) do |u|
      problem "Please use https:// for #{u}"
    end

    # Check for master branch GitHub archives.
    urls.grep(%r{^https://github\.com/.*archive/master\.(tar\.gz|zip)$}) do
      problem "Use versioned rather than branch tarballs for stable checksums."
    end

    # Use new-style archive downloads
    urls.each do |u|
      next unless u =~ %r{https://.*github.*/(?:tar|zip)ball/} && u !~ /\.git$/
      problem "Use /archive/ URLs for GitHub tarballs (url is #{u})."
    end

    # Don't use GitHub .zip files
    urls.each do |u|
      next unless u =~ %r{https://.*github.*/(archive|releases)/.*\.zip$} && u !~ %r{releases/download}
      problem "Use GitHub tarballs rather than zipballs (url is #{u})."
    end

    # Don't use GitHub codeload URLs
    urls.each do |u|
      next unless u =~ %r{https?://codeload\.github\.com/(.+)/(.+)/(?:tar\.gz|zip)/(.+)}
      problem <<-EOS.undent
        use GitHub archive URLs:
          https://github.com/#{$1}/#{$2}/archive/#{$3}.tar.gz
        Rather than codeload:
          #{u}
      EOS
    end

    # Check for Maven Central urls, prefer HTTPS redirector over specific host
    urls.each do |u|
      next unless u =~ %r{https?://(?:central|repo\d+)\.maven\.org/maven2/(.+)$}
      problem "#{u} should be `https://search.maven.org/remotecontent?filepath=#{$1}`"
    end

    return unless @online
    urls.each do |url|
      next if !@strict && mirrors.include?(url)

      strategy = DownloadStrategyDetector.detect(url, using)
      if strategy <= CurlDownloadStrategy && !url.start_with?("file")
        # A `brew mirror`'ed URL is usually not yet reachable at the time of
        # pull request.
        next if url =~ %r{^https://dl.bintray.com/homebrew/mirror/}
        if http_content_problem = FormulaAuditor.check_http_content(url)
          problem http_content_problem
        end
      elsif strategy <= GitDownloadStrategy
        unless Utils.git_remote_exists url
          problem "The URL #{url} is not a valid git URL"
        end
      elsif strategy <= SubversionDownloadStrategy
        next unless DevelopmentTools.subversion_handles_most_https_certificates?
        unless Utils.svn_remote_exists url
          problem "The URL #{url} is not a valid svn URL"
        end
      end
    end
  end

  def problem(text)
    @problems << text
  end
end
