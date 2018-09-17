#:  * `audit` [`--strict`] [`--fix`] [`--online`] [`--new-formula`] [`--display-cop-names`] [`--display-filename`] [`--only=`<method>|`--except=`<method>] [`--only-cops=`<cops>|`--except-cops=`<cops>] [<formulae>]:
#:    Check <formulae> for Homebrew coding style violations. This should be
#:    run before submitting a new formula.
#:
#:    If no <formulae> are provided, all of them are checked.
#:
#:    If `--strict` is passed, additional checks are run, including RuboCop
#:    style checks.
#:
#:    If `--fix` is passed, style violations will be
#:    automatically fixed using RuboCop's auto-correct feature.
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
#:    Passing `--only=`<method> will run only the methods named `audit_<method>`,
#:    while `--except=`<method> will skip the methods named `audit_<method>`.
#:    For either option <method> should be a comma-separated list.
#:
#:    Passing `--only-cops=`<cops> will check for violations of only the listed
#:    RuboCop <cops>, while `--except-cops=`<cops> will skip checking the listed
#:    <cops>. For either option <cops> should be a comma-separated list of cop names.
#:
#:    `audit` exits with a non-zero status if any errors are found. This is useful,
#:    for instance, for implementing pre-commit hooks.

# Undocumented options:
#     `-D` activates debugging and profiling of the audit methods (not the same as `--debug`)

require "formula"
require "formula_versions"
require "utils/curl"
require "extend/ENV"
require "formula_cellar_checks"
require "cmd/search"
require "style"
require "date"
require "missing_formula"
require "digest"
require "cli_parser"

module Homebrew
  module_function

  def audit
    Homebrew::CLI::Parser.parse do
      switch      "--strict"
      switch      "--online"
      switch      "--new-formula"
      switch      "--fix"
      switch      "--display-cop-names"
      switch      "--display-filename"
      switch      "-D", "--audit-debug", description: "Activates debugging and profiling"
      switch      :verbose
      switch      :debug
      comma_array "--only"
      comma_array "--except"
      comma_array "--only-cops"
      comma_array "--except-cops"
    end

    Homebrew.auditing = true
    inject_dump_stats!(FormulaAuditor, /^audit_/) if args.audit_debug?

    formula_count = 0
    problem_count = 0
    corrected_problem_count = 0
    new_formula_problem_count = 0
    new_formula = args.new_formula?
    strict = new_formula || args.strict?
    online = new_formula || args.online?

    ENV.activate_extensions!
    ENV.setup_build_environment

    if ARGV.named.empty?
      ff = Formula
      files = Tap.map(&:formula_dir)
    else
      ff = ARGV.resolved_formulae
      files = ARGV.resolved_formulae.map(&:path)
    end

    only_cops = args.only_cops
    except_cops = args.except_cops

    if only_cops && except_cops
      odie "--only-cops and --except-cops cannot be used simultaneously!"
    elsif (only_cops || except_cops) && (strict || args.only)
      odie "--only-cops/--except-cops and --strict/--only cannot be used simultaneously"
    end

    options = { fix: args.fix?, realpath: true }

    if only_cops
      options[:only_cops] = only_cops
      args.only = ["style"]
    elsif args.new_formula?
      nil
    elsif strict
      options[:except_cops] = [:NewFormulaAudit]
    elsif except_cops
      options[:except_cops] = except_cops
    elsif !strict
      options[:only_cops] = [:FormulaAudit]
    end

    options[:display_cop_names] = args.display_cop_names?
    # Check style in a single batch run up front for performance
    style_results = Style.check_style_json(files, options)

    new_formula_problem_lines = []
    ff.sort.each do |f|
      options = { new_formula: new_formula, strict: strict, online: online, only: args.only, except: args.except }
      options[:style_offenses] = style_results.file_offenses(f.path)
      fa = FormulaAuditor.new(f, options)
      fa.audit
      next if fa.problems.empty? && fa.new_formula_problems.empty?

      fa.problems
      formula_count += 1
      problem_count += fa.problems.size
      problem_lines = format_problem_lines(fa.problems)
      corrected_problem_count = options[:style_offenses].count(&:corrected?)
      new_formula_problem_lines = format_problem_lines(fa.new_formula_problems)
      if args.display_filename?
        puts problem_lines.map { |s| "#{f.path}: #{s}" }
      else
        puts "#{f.full_name}:", problem_lines.map { |s| "  #{s}" }
      end
    end

    created_pr_comment = false
    if new_formula && !new_formula_problem_lines.empty?
      begin
        if GitHub.create_issue_comment(new_formula_problem_lines.join("\n"))
          created_pr_comment = true
        end
      rescue *GitHub.api_errors => e
        opoo "Unable to create issue comment: #{e.message}"
      end
    end

    unless created_pr_comment
      new_formula_problem_count += new_formula_problem_lines.size
      puts new_formula_problem_lines.map { |s| "  #{s}" }
    end

    total_problems_count = problem_count + new_formula_problem_count
    problem_plural = Formatter.pluralize(total_problems_count, "problem")
    formula_plural = Formatter.pluralize(formula_count, "formula")
    corrected_problem_plural = Formatter.pluralize(corrected_problem_count, "problem")
    errors_summary = "#{problem_plural} in #{formula_plural} detected"
    if corrected_problem_count.positive?
      errors_summary += ", #{corrected_problem_plural} corrected"
    end

    if problem_count.positive? ||
       (new_formula_problem_count.positive? && !created_pr_comment)
      ofail errors_summary
    end
  end

  def format_problem_lines(problems)
    problems.map { |p| "* #{p.chomp.gsub("\n", "\n    ")}" }
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

    attr_reader :formula, :text, :problems, :new_formula_problems

    def initialize(formula, options = {})
      @formula = formula
      @new_formula = options[:new_formula] && !formula.versioned_formula?
      @strict = options[:strict]
      @online = options[:online]
      @display_cop_names = options[:display_cop_names]
      @only = options[:only]
      @except = options[:except]
      # Accept precomputed style offense results, for efficiency
      @style_offenses = options[:style_offenses]
      # Allow the actual official-ness of a formula to be overridden, for testing purposes
      @official_tap = formula.tap&.official? || options[:official_tap]
      @problems = []
      @new_formula_problems = []
      @text = FormulaText.new(formula.path)
      @specs = %w[stable devel head].map { |s| formula.send(s) }.compact
    end

    def audit_style
      return unless @style_offenses

      @style_offenses.each do |offense|
        if offense.cop_name.start_with?("NewFormulaAudit")
          next if formula.versioned_formula?

          new_formula_problem offense.to_s(display_cop_name: @display_cop_names)
          next
        end
        problem offense.to_s(display_cop_name: @display_cop_names)
      end
    end

    def audit_file
      # Under normal circumstances (umask 0022), we expect a file mode of 644. If
      # the user's umask is more restrictive, respect that by masking out the
      # corresponding bits. (The also included 0100000 flag means regular file.)
      wanted_mode = 0100644 & ~File.umask
      actual_mode = formula.path.stat.mode
      unless actual_mode == wanted_mode
        problem format("Incorrect file permissions (%03<actual>o): chmod %03<wanted>o %{path}",
                       actual: actual_mode & 0777,
                       wanted: wanted_mode & 0777,
                       path:   formula.path)
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
      elsif ARGV.build_stable? && formula.stable? &&
            !(versioned_formulae = formula.versioned_formulae).empty?
        versioned_aliases = formula.aliases.grep(/.@\d/)
        _, last_alias_version = versioned_formulae.map(&:name).last.split("@")
        major, minor, = formula.version.to_s.split(".")
        alias_name_major = "#{formula.name}@#{major}"
        alias_name_major_minor = "#{alias_name_major}.#{minor}"
        alias_name = if last_alias_version.split(".").length == 1
          alias_name_major
        else
          alias_name_major_minor
        end
        valid_alias_names = [alias_name_major, alias_name_major_minor]

        unless formula.tap&.core_tap?
          versioned_aliases.map! { |a| "#{formula.tap}/#{a}" }
          valid_alias_names.map! { |a| "#{formula.tap}/#{a}" }
        end

        valid_versioned_aliases = versioned_aliases & valid_alias_names
        invalid_versioned_aliases = versioned_aliases - valid_alias_names

        if valid_versioned_aliases.empty?
          if formula.tap
            problem <<~EOS
              Formula has other versions so create a versioned alias:
                cd #{formula.tap.alias_dir}
                ln -s #{formula.path.to_s.gsub(formula.tap.path, "..")} #{alias_name}
            EOS
          else
            problem "Formula has other versions so create an alias named #{alias_name}."
          end
        end

        unless invalid_versioned_aliases.empty?
          problem <<~EOS
            Formula has invalid versioned aliases:
              #{invalid_versioned_aliases.join("\n  ")}
          EOS
        end
      end
    end

    def self.aliases
      # core aliases + tap alias names + tap alias full name
      @aliases ||= Formula.aliases + Formula.tap_aliases
    end

    def audit_formula_name
      return unless @strict
      # skip for non-official taps
      return unless @official_tap

      name = formula.name

      if MissingFormula.blacklisted_reason(name)
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

      return if formula.core_formula?
      return unless Formula.core_names.include?(name)

      problem "Formula name conflicts with existing core formula."
    end

    def audit_deps
      @specs.each do |spec|
        # Check for things we don't like to depend on.
        # We allow non-Homebrew installs whenever possible.
        options_message = "Formulae should not have optional or recommended dependencies"
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

          if self.class.aliases.include?(dep.name) &&
             (dep_f.core_formula? || !dep_f.versioned_formula?)
            problem "Dependency '#{dep.name}' is an alias; use the canonical name '#{dep.to_formula.full_name}'."
          end

          if @new_formula && dep_f.keg_only_reason &&
             !["openssl", "apr", "apr-util"].include?(dep.name) &&
             dep_f.keg_only_reason.reason == :provided_by_macos
            new_formula_problem(
              "Dependency '#{dep.name}' may be unnecessary as it is provided " \
              "by macOS; try to build this formula without it.",
            )
          end

          dep.options.each do |opt|
            next if dep_f.option_defined?(opt)
            next if dep_f.requirements.find do |r|
              if r.recommended?
                opt.name == "with-#{r.name}"
              elsif r.optional?
                opt.name == "without-#{r.name}"
              end
            end

            problem "Dependency #{dep} does not define option #{opt.name.inspect}"
          end

          if dep.name == "git"
            problem "Don't use git as a dependency (it's always available)"
          end

          if dep.tags.include?(:run)
            problem "Dependency '#{dep.name}' is marked as :run. Remove :run; it is a no-op."
          end

          next unless @new_formula
          next unless @official_tap

          if dep.tags.include?(:recommended) || dep.tags.include?(:optional)
            new_formula_problem options_message
          end
        end

        next unless @new_formula
        next unless @official_tap

        if spec.requirements.map(&:recommended?).any? || spec.requirements.map(&:optional?).any?
          new_formula_problem options_message
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
        problem <<~EOS
          '#{first_word}' from the keg_only reason should be '#{first_word.downcase}'.
        EOS
      end

      return unless reason.end_with?(".")

      problem "keg_only reason should not end with a period."
    end

    def audit_homepage
      homepage = formula.homepage

      return if homepage.nil? || homepage.empty?

      return unless @online

      return unless DevelopmentTools.curl_handles_most_https_certificates?

      if http_content_problem = curl_check_http_content(homepage,
                                  user_agents: [:browser, :default],
                                  check_content: true,
                                  strict: @strict)
        problem http_content_problem
      end
    end

    def audit_bottle_disabled
      return unless formula.bottle_disabled?
      return if formula.bottle_unneeded?

      if !formula.bottle_disable_reason.valid?
        problem "Unrecognized bottle modifier"
      else
        bottle_disabled_whitelist = %w[
          cryptopp
          leafnode
        ]
        return if bottle_disabled_whitelist.include?(formula.name)

        problem "Formulae should not use `bottle :disabled`" if @official_tap
      end
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

      new_formula_problem "GitHub fork (not canonical repository)" if metadata["fork"]
      if formula&.tap&.core_tap? &&
         (metadata["forks_count"] < 30) && (metadata["subscribers_count"] < 30) &&
         (metadata["stargazers_count"] < 75)
        new_formula_problem "GitHub repository not notable enough (<30 forks, <30 watchers and <75 stars)"
      end

      return if Date.parse(metadata["created_at"]) <= (Date.today - 30)

      new_formula_problem "GitHub repository too new (<30 days old)"
    end

    def audit_specs
      if head_only?(formula) && formula.tap.to_s.downcase !~ %r{[-/]head-only$}
        problem "Head-only (no stable download)"
      end

      if devel_only?(formula) && formula.tap.to_s.downcase !~ %r{[-/]devel-only$}
        problem "Devel-only (no stable download)"
      end

      %w[Stable Devel HEAD].each do |name|
        spec_name = name.downcase.to_sym
        next unless spec = formula.send(spec_name)

        ra = ResourceAuditor.new(spec, spec_name, online: @online, strict: @strict).audit
        problems.concat ra.problems.map { |problem| "#{name}: #{problem}" }

        spec.resources.each_value do |resource|
          ra = ResourceAuditor.new(resource, spec_name, online: @online, strict: @strict).audit
          problems.concat ra.problems.map { |problem|
            "#{name} resource #{resource.name.inspect}: #{problem}"
          }
        end

        next if spec.patches.empty?
        next unless @new_formula

        new_formula_problem(
          "Formulae should not require patches to build. " \
          "Patches should be submitted and accepted upstream first.",
        )
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

      if formula.head || formula.devel
        unstable_spec_message = "Formulae should not have a `HEAD` or `devel` spec"
        if @new_formula
          new_formula_problem unstable_spec_message
        elsif formula.versioned_formula?
          versioned_unstable_spec = %w[
            bash-completion@2
            imagemagick@6
            openssl@1.1
            python@2
          ]
          problem unstable_spec_message unless versioned_unstable_spec.include?(formula.name)
        end
      end

      throttled = %w[
        aws-sdk-cpp 10
        awscli 10
        heroku 10
        quicktype 10
        vim 50
      ]

      throttled.each_slice(2).to_a.map do |a, b|
        next if formula.stable.nil?

        version = formula.stable.version.to_s.split(".").last.to_i
        if @strict && a == formula.name && version.modulo(b.to_i).nonzero?
          problem "should only be updated every #{b} releases on multiples of #{b}"
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
        libepoxy 1.5.0
        gtk-mac-integration 2.1.2
      ].each_slice(2).to_a.map do |formula, version|
        [formula, version.split(".")[0..1].join(".")]
      end

      stable = formula.stable
      case stable&.url
      when /[\d\._-](alpha|beta|rc\d)/
        matched = Regexp.last_match(1)
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

      previous_version_and_checksum = fv.previous_version_and_checksum("origin/master")
      [:stable, :devel].each do |spec_sym|
        next unless spec = formula.send(spec_sym)
        next unless previous_version_and_checksum[spec_sym][:version] == spec.version
        next if previous_version_and_checksum[spec_sym][:checksum] == spec.checksum

        problem(
          "#{spec_sym}: sha256 changed without the version also changing; " \
          "please create an issue upstream to rule out malicious " \
          "circumstances and to find out why the file changed.",
        )
      end

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
        map_includes_version = spec_version_scheme_map.key?(spec_version)
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

    def audit_text
      bin_names = Set.new
      bin_names << formula.name
      bin_names += formula.aliases
      [formula.bin, formula.sbin].each do |dir|
        next unless dir.exist?

        bin_names += dir.children.map(&:basename).map(&:to_s)
      end
      bin_names.each do |name|
        ["system", "shell_output", "pipe_output"].each do |cmd|
          if text =~ /test do.*#{cmd}[\(\s]+['"]#{Regexp.escape(name)}[\s'"]/m
            problem %Q(fully scope test #{cmd} calls e.g. #{cmd} "\#{bin}/#{name}")
          end
        end
      end
    end

    def audit_lines
      text.without_patch.split("\n").each_with_index do |line, lineno|
        line_problems(line, lineno + 1)
      end
    end

    def line_problems(line, _lineno)
      # Check for string interpolation of single values.
      if line =~ /(system|inreplace|gsub!|change_make_var!).*[ ,]"#\{([\w.]+)\}"/
        problem "Don't need to interpolate \"#{Regexp.last_match(2)}\" with #{Regexp.last_match(1)}"
      end

      # Check for string concatenation; prefer interpolation
      if line =~ /(#\{\w+\s*\+\s*['"][^}]+\})/
        problem "Try not to concatenate paths in string interpolation:\n   #{Regexp.last_match(1)}"
      end

      # Prefer formula path shortcuts in Pathname+
      if line =~ %r{\(\s*(prefix\s*\+\s*(['"])(bin|include|libexec|lib|sbin|share|Frameworks)[/'"])}
        problem(
          "\"(#{Regexp.last_match(1)}...#{Regexp.last_match(2)})\" should" \
          " be \"(#{Regexp.last_match(3).downcase}+...)\"",
        )
      end

      problem "Use separate make calls" if line.include?("make && make")

      if line =~ /JAVA_HOME/i && !formula.requirements.map(&:class).include?(JavaRequirement)
        problem "Use `depends_on :java` to set JAVA_HOME"
      end

      return unless @strict

      if @official_tap && line.include?("env :std")
        problem "`env :std` in official tap formulae is deprecated"
      end

      if line.include?("env :userpaths")
        problem "`env :userpaths` in formulae is deprecated"
      end

      if line =~ /system ((["'])[^"' ]*(?:\s[^"' ]*)+\2)/
        bad_system = Regexp.last_match(1)
        unless %w[| < > & ; *].any? { |c| bad_system.include? c }
          good_system = bad_system.gsub(" ", "\", \"")
          problem "Use `system #{good_system}` instead of `system #{bad_system}` "
        end
      end

      problem "`#{Regexp.last_match(1)}` is now unnecessary" if line =~ /(require ["']formula["'])/

      if line =~ %r{#\{share\}/#{Regexp.escape(formula.name)}[/'"]}
        problem "Use \#{pkgshare} instead of \#{share}/#{formula.name}"
      end

      if line =~ /depends_on .+ if build\.with(out)?\?\(?["']\w+["']\)?/
        problem "`Use :optional` or `:recommended` instead of `#{Regexp.last_match(0)}`"
      end

      return unless line =~ %r{share(\s*[/+]\s*)(['"])#{Regexp.escape(formula.name)}(?:\2|/)}

      problem "Use pkgshare instead of (share#{Regexp.last_match(1)}\"#{formula.name}\")"
    end

    def audit_reverse_migration
      # Only enforce for new formula being re-added to core and official taps
      return unless @strict
      return unless @official_tap
      return unless formula.tap.tap_migrations.key?(formula.name)

      problem <<~EOS
        #{formula.name} seems to be listed in tap_migrations.json!
        Please remove #{formula.name} from present tap & tap_migrations.json
        before submitting it to Homebrew/homebrew-#{formula.tap.repo}.
      EOS
    end

    def audit_prefix_has_contents
      return unless formula.prefix.directory?
      return unless Keg.new(formula.prefix).empty_installation?

      problem <<~EOS
        The installation seems to be empty. Please ensure the prefix
        is set correctly and expected files are installed.
        The prefix configure/make argument may be case-sensitive.
      EOS
    end

    def audit_url_is_not_binary
      return unless @official_tap

      urls = @specs.map(&:url)

      urls.each do |url|
        if url =~ /darwin/i && (url =~ /x86_64/i || url =~ /amd64/i)
          problem "#{url} looks like a binary package, not a source archive. Official taps are source-only."
        end
      end
    end

    def quote_dep(dep)
      dep.is_a?(Symbol) ? dep.inspect : "'#{dep}'"
    end

    def problem_if_output(output)
      problem(output) if output
    end

    def audit
      only_audits = @only
      except_audits = @except
      if only_audits && except_audits
        odie "--only and --except cannot be used simultaneously!"
      end

      methods.map(&:to_s).grep(/^audit_/).each do |audit_method_name|
        name = audit_method_name.gsub(/^audit_/, "")
        if only_audits
          next unless only_audits.include?(name)
        elsif except_audits
          next if except_audits.include?(name)
        end
        send(audit_method_name)
      end
    end

    private

    def problem(p)
      @problems << p
    end

    def new_formula_problem(p)
      @new_formula_problems << p
    end

    def head_only?(formula)
      formula.head && formula.devel.nil? && formula.stable.nil?
    end

    def devel_only?(formula)
      formula.devel && formula.stable.nil?
    end
  end

  class ResourceAuditor
    attr_reader :name, :version, :checksum, :url, :mirrors, :using, :specs, :owner
    attr_reader :spec_name, :problems

    def initialize(resource, spec_name, options = {})
      @name     = resource.name
      @version  = resource.version
      @checksum = resource.checksum
      @url      = resource.url
      @mirrors  = resource.mirrors
      @using    = resource.using
      @specs    = resource.specs
      @owner    = resource.owner
      @spec_name = spec_name
      @online    = options[:online]
      @strict    = options[:strict]
      @problems  = []
    end

    def audit
      audit_version
      audit_download_strategy
      audit_urls
      self
    end

    def audit_version
      if version.nil?
        problem "missing version"
      elsif version.blank?
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

    def audit_download_strategy
      if url =~ %r{^(cvs|bzr|hg|fossil)://} || url =~ %r{^(svn)\+http://}
        problem "Use of the #{$&} scheme is deprecated, pass `:using => :#{Regexp.last_match(1)}` instead"
      end

      url_strategy = DownloadStrategyDetector.detect(url)

      if using == :git || url_strategy == GitDownloadStrategy
        if specs[:tag] && !specs[:revision]
          problem "Git should specify :revision when a :tag is specified."
        end
      end

      return unless using

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

    def self.curl_openssl_and_deps
      @curl_openssl_and_deps ||= begin
        formulae_names = ["curl", "openssl"]
        formulae_names += formulae_names.flat_map do |f|
          Formula[f].recursive_dependencies.map(&:name)
        end
        formulae_names.uniq
      rescue FormulaUnavailableError
        []
      end
    end

    def audit_urls
      urls = [url] + mirrors

      curl_openssl_or_deps = ResourceAuditor.curl_openssl_and_deps.include?(owner.name)

      if spec_name == :stable && curl_openssl_or_deps
        problem "should not use xz tarballs" if url.end_with?(".xz")

        unless urls.find { |u| u.start_with?("http://") }
          problem "should always include at least one HTTP mirror"
        end
      end

      return unless @online

      urls.each do |url|
        next if !@strict && mirrors.include?(url)

        strategy = DownloadStrategyDetector.detect(url, using)
        if strategy <= CurlDownloadStrategy && !url.start_with?("file")
          # A `brew mirror`'ed URL is usually not yet reachable at the time of
          # pull request.
          next if url =~ %r{^https://dl.bintray.com/homebrew/mirror/}

          if http_content_problem = curl_check_http_content(url, require_http: curl_openssl_or_deps)
            problem http_content_problem
          end
        elsif strategy <= GitDownloadStrategy
          unless Utils.git_remote_exists? url
            problem "The URL #{url} is not a valid git URL"
          end
        elsif strategy <= SubversionDownloadStrategy
          next unless DevelopmentTools.subversion_handles_most_https_certificates?
          next unless Utils.svn_available?

          unless Utils.svn_remote_exists? url
            problem "The URL #{url} is not a valid svn URL"
          end
        end
      end
    end

    def problem(text)
      @problems << text
    end
  end
end
