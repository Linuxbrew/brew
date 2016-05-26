# Comprehensively test a formula or pull request.
#
# Usage: brew test-bot [options...] <pull-request|formula>
#
# Options:
# --keep-logs:     Write and keep log files under ./brewbot/.
# --cleanup:       Clean the Homebrew directory. Very dangerous. Use with care.
# --clean-cache:   Remove all cached downloads. Use with care.
# --skip-setup:    Don't check the local system is setup correctly.
# --skip-homebrew: Don't check Homebrew's files and tests are all valid.
# --junit:         Generate a JUnit XML test results file.
# --no-bottle:     Run brew install without --build-bottle.
# --keep-old:      Run brew bottle --keep-old to build new bottles for a single platform.
# --legacy         Build formula from legacy Homebrew/legacy-homebrew repo.
#                  (TODO remove it when it's not longer necessary)
# --HEAD:          Run brew install with --HEAD.
# --local:         Ask Homebrew to write verbose logs under ./logs/ and set HOME to ./home/.
# --tap=<tap>:     Use the git repository of the given tap.
# --dry-run:       Just print commands, don't run them.
# --fail-fast:     Immediately exit on a failing step.
# --verbose:       Print test step output in realtime. Has the side effect of passing output
#                  as raw bytes instead of re-encoding in UTF-8.
# --fast:          Don't install any packages, but run e.g. audit anyway.
# --keep-tmp:      Keep temporary files written by main installs and tests that are run.
#
# --ci-master:           Shortcut for Homebrew master branch CI options.
# --ci-pr:               Shortcut for Homebrew pull request CI options.
# --ci-testing:          Shortcut for Homebrew testing CI options.
# --ci-upload:           Homebrew CI bottle upload.

require "formula"
require "utils"
require "date"
require "rexml/document"
require "rexml/xmldecl"
require "rexml/cdata"
require "tap"

module Homebrew
  BYTES_IN_1_MEGABYTE = 1024*1024
  MAX_STEP_OUTPUT_SIZE = BYTES_IN_1_MEGABYTE - (200*1024) # margin of safety

  HOMEBREW_TAP_REGEX = %r{^([\w-]+)/homebrew-([\w-]+)$}

  def ruby_has_encoding?
    String.method_defined?(:force_encoding)
  end

  if ruby_has_encoding?
    def fix_encoding!(str)
      # Assume we are starting from a "mostly" UTF-8 string
      str.force_encoding(Encoding::UTF_8)
      return str if str.valid_encoding?
      str.encode!(Encoding::UTF_16, :invalid => :replace)
      str.encode!(Encoding::UTF_8)
    end
  elsif require "iconv"
    def fix_encoding!(str)
      Iconv.conv("UTF-8//IGNORE", "UTF-8", str)
    end
  else
    def fix_encoding!(str)
      str
    end
  end

  def resolve_test_tap
    if tap = ARGV.value("tap")
      return Tap.fetch(tap)
    end

    if (tap = ENV["TRAVIS_REPO_SLUG"]) && (tap =~ HOMEBREW_TAP_REGEX)
      return Tap.fetch(tap)
    end

    if ENV["UPSTREAM_BOT_PARAMS"]
      bot_argv = ENV["UPSTREAM_BOT_PARAMS"].split " "
      bot_argv.extend HomebrewArgvExtension
      if tap = bot_argv.value("tap")
        return Tap.fetch(tap)
      end
    end

    if git_url = ENV["UPSTREAM_GIT_URL"] || ENV["GIT_URL"]
      # Also can get tap from Jenkins GIT_URL.
      url_path = git_url.sub(%r{^https?://github\.com/}, "").chomp("/").sub(%r{\.git$}, "")
      begin
        return Tap.fetch(url_path) if url_path =~ HOMEBREW_TAP_REGEX
      rescue
      end
    end

    CoreTap.instance
  end

  class Step
    attr_reader :command, :name, :status, :output, :time

    def initialize(test, command, options = {})
      @test = test
      @category = test.category
      @command = command
      @puts_output_on_success = options[:puts_output_on_success]
      @name = command[1].delete("-")
      @status = :running
      @repository = options[:repository] || HOMEBREW_REPOSITORY
      @time = 0
    end

    def log_file_path
      file = "#{@category}.#{@name}.txt"
      root = @test.log_root
      root ? root + file : file
    end

    def command_short
      (@command - %w[brew --force --retry --verbose --build-bottle --rb]).join(" ")
    end

    def passed?
      @status == :passed
    end

    def failed?
      @status == :failed
    end

    def puts_command
      if ENV["TRAVIS"]
        @@travis_step_num ||= 0
        @travis_fold_id = @command.first(2).join(".") + ".#{@@travis_step_num += 1}"
        @travis_timer_id = rand(2**32).to_s(16)
        puts "travis_fold:start:#{@travis_fold_id}"
        puts "travis_time:start:#{@travis_timer_id}"
      end
      puts "#{Tty.blue}==>#{Tty.white} #{@command.join(" ")}#{Tty.reset}"
    end

    def puts_result
      if ENV["TRAVIS"]
        travis_start_time = @start_time.to_i*1000000000
        travis_end_time = @end_time.to_i*1000000000
        travis_duration = travis_end_time - travis_start_time
        puts "#{Tty.white}==>#{Tty.green} PASSED#{Tty.reset}" if passed?
        puts "travis_time:end:#{@travis_timer_id},start=#{travis_start_time},finish=#{travis_end_time},duration=#{travis_duration}"
        puts "travis_fold:end:#{@travis_fold_id}"
      end
      puts "#{Tty.white}==>#{Tty.red} FAILED#{Tty.reset}" if failed?
    end

    def has_output?
      @output && !@output.empty?
    end

    def time
      @end_time - @start_time
    end

    def run
      @start_time = Time.now

      puts_command
      if ARGV.include? "--dry-run"
        @end_time = Time.now
        @status = :passed
        puts_result
        return
      end

      verbose = ARGV.verbose?
      # Step may produce arbitrary output and we read it bytewise, so must
      # buffer it as binary and convert to UTF-8 once complete
      output = Homebrew.ruby_has_encoding? ? "".encode!("BINARY") : ""
      working_dir = Pathname.new(@command.first == "git" ? @repository : Dir.pwd)
      read, write = IO.pipe

      begin
        pid = fork do
          read.close
          $stdout.reopen(write)
          $stderr.reopen(write)
          write.close
          working_dir.cd { exec(*@command) }
        end
        write.close
        while buf = read.readpartial(4096)
          if verbose
            print buf
            $stdout.flush
          end
          output << buf
        end
      rescue EOFError
      ensure
        read.close
      end

      Process.wait(pid)
      @end_time = Time.now
      @status = $?.success? ? :passed : :failed
      puts_result


      unless output.empty?
        @output = Homebrew.fix_encoding!(output)
        puts @output if (failed? || @puts_output_on_success) && !verbose
        File.write(log_file_path, @output) if ARGV.include? "--keep-logs"
      end

      exit 1 if ARGV.include?("--fail-fast") && failed?
    end
  end

  class Test
    attr_reader :log_root, :category, :name, :steps

    def initialize(argument, options={})
      @hash = nil
      @url = nil
      @formulae = []
      @added_formulae = []
      @modified_formula = []
      @steps = []
      @tap = options.fetch(:tap, CoreTap.instance)
      @repository = @tap.path
      @skip_homebrew = options.fetch(:skip_homebrew, false)

      if quiet_system "git", "-C", @repository.to_s, "rev-parse", "--verify", "-q", argument
        @hash = argument
      elsif url_match = argument.match(HOMEBREW_PULL_OR_COMMIT_URL_REGEX)
        @url = url_match[0]
      elsif canonical_formula_name = safe_formula_canonical_name(argument)
        @formulae = [canonical_formula_name]
      else
        raise ArgumentError.new("#{argument} is not a pull request URL, commit URL or formula name.")
      end

      @category = __method__
      @brewbot_root = Pathname.pwd + "brewbot"
      FileUtils.mkdir_p @brewbot_root
    end

    def no_args?
      @hash == "HEAD"
    end

    def safe_formula_canonical_name(formula_name)
      Formulary.factory(formula_name).full_name
    rescue TapFormulaUnavailableError => e
      raise if e.tap.installed?
      test "brew", "tap", e.tap.name
      retry unless steps.last.failed?
    rescue FormulaUnavailableError, TapFormulaAmbiguityError, TapFormulaWithOldnameAmbiguityError
    end

    def git(*args)
      @repository.cd { Utils.popen_read("git", *args) }
    end

    def download
      def shorten_revision(revision)
        git("rev-parse", "--short", revision).strip
      end

      def current_sha1
        shorten_revision "HEAD"
      end

      def current_branch
        git("symbolic-ref", "HEAD").gsub("refs/heads/", "").strip
      end

      def single_commit?(start_revision, end_revision)
        git("rev-list", "--count", "#{start_revision}..#{end_revision}").to_i == 1
      end

      def diff_formulae(start_revision, end_revision, path, filter)
        git(
          "diff-tree", "-r", "--name-only", "--diff-filter=#{filter}",
          start_revision, end_revision, "--", path
        ).lines.map do |line|
          file = Pathname.new line.chomp
          next unless file.extname == ".rb"
          @tap.formula_file_to_name(file)
        end.compact
      end

      @category = __method__
      @start_branch = current_branch

      travis_pr = ENV["TRAVIS_PULL_REQUEST"] && ENV["TRAVIS_PULL_REQUEST"] != "false"

      # Use Jenkins GitHub Pull Request Builder plugin variables for
      # pull request jobs.
      if ENV["ghprbPullLink"]
        @url = ENV["ghprbPullLink"]
        @hash = nil
        test "git", "checkout", "origin/master"
      # Use Travis CI pull-request variables for pull request jobs.
      elsif travis_pr
        @url = "https://github.com/#{ENV["TRAVIS_REPO_SLUG"]}/pull/#{ENV["TRAVIS_PULL_REQUEST"]}"
        @hash = nil
      elsif ENV["CI_PULL_REQUEST"] && !ENV["CI_PULL_REQUEST"].empty?
        # Circle CI build of a pull request.
        @url = ENV["CI_PULL_REQUEST"]
        @hash = nil
      elsif ENV["GIT_BRANCH"] && ENV["GIT_BRANCH"].include?(":")
        # Docker automated build of a pull request
        user = ENV["GIT_BRANCH"].split(":")[0]
        @url = "https://github.com/#{user}/linuxbrew/commit/#{ENV["GIT_SHA1"]}"
        @hash = nil
      end

      # Use Jenkins Git plugin variables for master branch jobs.
      if ENV["GIT_PREVIOUS_COMMIT"] && ENV["GIT_COMMIT"]
        diff_start_sha1 = ENV["GIT_PREVIOUS_COMMIT"]
        diff_end_sha1 = ENV["GIT_COMMIT"]
      # Use Travis CI Git variables for master or branch jobs.
      elsif ENV["TRAVIS_COMMIT_RANGE"]
        diff_start_sha1, diff_end_sha1 = ENV["TRAVIS_COMMIT_RANGE"].split "..."
      # Otherwise just use the current SHA-1 (which may be overriden later)
      else
        diff_end_sha1 = diff_start_sha1 = current_sha1
      end

      diff_start_sha1 = git("merge-base", diff_start_sha1, diff_end_sha1).strip

      # Handle no arguments being passed on the command-line e.g. `brew test-bot`.
      if no_args?
        if diff_start_sha1 == diff_end_sha1 || \
           single_commit?(diff_start_sha1, diff_end_sha1)
          @name = diff_end_sha1
        else
          @name = "#{diff_start_sha1}-#{diff_end_sha1}"
        end
      # Handle formulae arguments being passed on the command-line e.g. `brew test-bot wget fish`.
      elsif @formulae && @formulae.any?
        @name = "#{@formulae.first}-#{diff_end_sha1}"
        diff_start_sha1 = diff_end_sha1
      # Handle a hash being passed on the command-line e.g. `brew test-bot 1a2b3c`.
      elsif @hash
        test "git", "checkout", @hash
        diff_start_sha1 = "#{@hash}^"
        diff_end_sha1 = @hash
        @name = @hash
      # Handle a URL being passed on the command-line or through Jenkins/Travis
      # environment variables e.g.
      # `brew test-bot https://github.com/Homebrew/homebrew-core/pull/678`.
      elsif @url
        # TODO: in future Travis CI may need to also use `brew pull` to e.g. push
        # the right commit to BrewTestBot.
        unless travis_pr
          diff_start_sha1 = current_sha1
          if ARGV.include?("--legacy")
            test "brew", "pull", "--clean", "--legacy", @url
          else
            test "brew", "pull", "--clean", @url
          end
          diff_end_sha1 = current_sha1
        end
        @short_url = @url.gsub("https://github.com/", "")
        if @short_url.include? "/commit/"
          # 7 characters should be enough for a commit (not 40).
          @short_url.gsub!(/(commit\/\w{7}).*/, '\1')
          @name = @short_url
        else
          @name = "#{@short_url}-#{diff_end_sha1}"
        end
      else
        raise "Cannot set @name: invalid command-line arguments!"
      end

      @log_root = @brewbot_root + @name
      FileUtils.mkdir_p @log_root

      return unless diff_start_sha1 != diff_end_sha1
      return if @url && steps.last && !steps.last.passed?

      formula_path = @tap.formula_dir.to_s
      @added_formulae += diff_formulae(diff_start_sha1, diff_end_sha1, formula_path, "A")
      @modified_formula += diff_formulae(diff_start_sha1, diff_end_sha1, formula_path, "M")
      @formulae += @added_formulae + @modified_formula
    end

    def skip(formula_name)
      puts "#{Tty.blue}==>#{Tty.white} SKIPPING: #{formula_name}#{Tty.reset}"
    end

    def satisfied_requirements?(formula, spec, dependency = nil)
      requirements = formula.send(spec).requirements

      unsatisfied_requirements = requirements.reject do |requirement|
        satisfied = false
        satisfied ||= requirement.satisfied?
        satisfied ||= requirement.optional?
        if !satisfied && requirement.default_formula?
          default = Formula[requirement.default_formula]
          satisfied = satisfied_requirements?(default, :stable, formula.full_name)
        end
        satisfied
      end

      if unsatisfied_requirements.empty?
        true
      else
        name = formula.full_name
        name += " (#{spec})" unless spec == :stable
        name += " (#{dependency} dependency)" if dependency
        skip name
        puts unsatisfied_requirements.map(&:message)
        false
      end
    end

    def setup
      @category = __method__
      return if ARGV.include? "--skip-setup"
      test "brew", "doctor" if !ENV["TRAVIS"] && ENV["HOMEBREW_RUBY"] != "1.8.7"
      test "brew", "--env"
      test "brew", "config"
    end

    def formula(formula_name)
      @category = "#{__method__}.#{formula_name}"

      test "brew", "uses", formula_name

      formula = Formulary.factory(formula_name)

      installed_gcc = false

      deps = []
      reqs = []

      fetch_args = [formula_name]
      fetch_args << "--build-bottle" if !ARGV.include?("--fast") && !ARGV.include?("--no-bottle") && !formula.bottle_disabled?
      fetch_args << "--force" if ARGV.include? "--cleanup"

      audit_args = [formula_name]
      audit_args << "--strict" << "--online" if @added_formulae.include? formula_name

      if formula.stable
        unless satisfied_requirements?(formula, :stable)
          test "brew", "fetch", "--retry", *fetch_args
          test "brew", "audit", *audit_args
          return
        end

        deps |= formula.stable.deps.to_a.reject(&:optional?)
        reqs |= formula.stable.requirements.to_a.reject(&:optional?)
      elsif formula.devel
        unless satisfied_requirements?(formula, :devel)
          test "brew", "fetch", "--retry", "--devel", *fetch_args
          test "brew", "audit", "--devel", *audit_args
          return
        end
      end

      if formula.devel && !ARGV.include?("--HEAD")
        deps |= formula.devel.deps.to_a.reject(&:optional?)
        reqs |= formula.devel.requirements.to_a.reject(&:optional?)
      end

      begin
        deps.each { |d| d.to_formula.recursive_dependencies }
      rescue TapFormulaUnavailableError => e
        raise if e.tap.installed?
        safe_system "brew", "tap", e.tap.name
        retry
      end

      begin
        deps.each do |dep|
          CompilerSelector.select_for(dep.to_formula)
        end
        CompilerSelector.select_for(formula)
      rescue CompilerSelectionError => e
        unless installed_gcc
          run_as_not_developer { test "brew", "install", "gcc" }
          installed_gcc = true
          OS::Mac.clear_version_cache
          retry
        end
        skip formula_name
        puts e.message
        return
      end

      conflicts = formula.conflicts
      formula.recursive_dependencies.each do |dependency|
        conflicts += dependency.to_formula.conflicts
      end

      conflicts.each do |conflict|
        confict_formula = Formulary.factory(conflict.name)

        if confict_formula.installed? && confict_formula.linked_keg.exist?
          test "brew", "unlink", "--force", conflict.name
        end
      end

      installed = Utils.popen_read("brew", "list").split("\n")
      dependencies = Utils.popen_read("brew", "deps", "--include-build", formula_name).split("\n")

      (installed & dependencies).each do |installed_dependency|
        installed_dependency_formula = Formulary.factory(installed_dependency)
        if installed_dependency_formula.installed? &&
           !installed_dependency_formula.keg_only? &&
           !installed_dependency_formula.linked_keg.exist?
          test "brew", "link", installed_dependency
        end
      end

      dependencies -= installed
      unchanged_dependencies = dependencies - @formulae
      changed_dependences = dependencies - unchanged_dependencies

      runtime_dependencies = Utils.popen_read("brew", "deps", formula_name).split("\n")
      build_dependencies = dependencies - runtime_dependencies
      unchanged_build_dependencies = build_dependencies - @formulae

      dependents = Utils.popen_read("brew", "uses", formula_name).split("\n")
      dependents -= @formulae
      dependents = dependents.map { |d| Formulary.factory(d) }

      bottled_dependents = dependents.select { |d| d.bottled? }
      testable_dependents = dependents.select { |d| d.bottled? && d.test_defined? }

      if (deps | reqs).any? { |d| d.name == "mercurial" && d.build? }
        run_as_not_developer { test "brew", "install", "mercurial" }
      end

      test "brew", "fetch", "--retry", *unchanged_dependencies unless unchanged_dependencies.empty?

      unless changed_dependences.empty?
        test "brew", "fetch", "--retry", "--build-bottle", *changed_dependences
        unless ARGV.include?("--fast")
          # Install changed dependencies as new bottles so we don't have checksum problems.
          test "brew", "install", "--build-bottle", *changed_dependences
          # Run postinstall on them because the tested formula might depend on
          # this step
          test "brew", "postinstall", *changed_dependences
        end
      end
      test "brew", "fetch", "--retry", *fetch_args
      test "brew", "uninstall", "--force", formula_name if formula.installed?

      # shared_*_args are applied to both the main and --devel spec
      shared_install_args = ["--verbose"]
      shared_install_args << "--keep-tmp" if ARGV.keep_tmp?
      # install_args is just for the main (stable, or devel if in a devel-only tap) spec
      install_args = []
      install_args << "--build-bottle" if !ARGV.include?("--fast") && !ARGV.include?("--no-bottle") && !formula.bottle_disabled?
      install_args << "--HEAD" if ARGV.include? "--HEAD"

      # Pass --devel or --HEAD to install in the event formulae lack stable. Supports devel-only/head-only.
      # head-only should not have devel, but devel-only can have head. Stable can have all three.
      if devel_only_tap? formula
        install_args << "--devel"
        formula_bottled = false
      elsif head_only_tap? formula
        install_args << "--HEAD"
        formula_bottled = false
      else
        formula_bottled = formula.bottled?
      end

      install_args.concat(shared_install_args)
      install_args << formula_name
      # Don't care about e.g. bottle failures for dependencies.
      install_passed = false
      run_as_not_developer do
        if !ARGV.include?("--fast") || formula_bottled || formula.bottle_unneeded?
          test "brew", "install", "--only-dependencies", *install_args unless dependencies.empty?
          test "brew", "install", *install_args
          install_passed = steps.last.passed?
        end
      end
      test "brew", "audit", *audit_args
      if install_passed
        if formula.stable? && !ARGV.include?("--fast") && !ARGV.include?("--no-bottle") && !formula.bottle_disabled?
          bottle_args = ["--verbose", "--rb", formula_name]
          bottle_args << "--keep-old" if ARGV.include? "--keep-old"
          test "brew", "bottle", *bottle_args
          bottle_step = steps.last
          if bottle_step.passed? && bottle_step.has_output?
            bottle_filename =
              bottle_step.output.gsub(/.*(\.\/\S+#{bottle_native_regex}).*/m, '\1')
            bottle_rb_filename = bottle_filename.gsub(/\.(\d+\.)?tar\.gz$/, ".rb")
            bottle_merge_args = ["--merge", "--write", "--no-commit", bottle_rb_filename]
            bottle_merge_args << "--keep-old" if ARGV.include? "--keep-old"
            test "brew", "bottle", *bottle_merge_args
            test "brew", "uninstall", "--force", formula_name
            FileUtils.ln bottle_filename, HOMEBREW_CACHE/bottle_filename, :force => true
            @formulae.delete(formula_name)
            if unchanged_build_dependencies.any?
              test "brew", "uninstall", "--force", *unchanged_build_dependencies
              unchanged_dependencies -= unchanged_build_dependencies
            end
            test "brew", "install", bottle_filename
          end
        end
        shared_test_args = ["--verbose"]
        shared_test_args << "--keep-tmp" if ARGV.keep_tmp?
        test "brew", "test", formula_name, *shared_test_args if formula.test_defined?

        before_linkage = Utils.popen_read("brew", "list").split("\n")
        bottled_dependents.each do |dependent|
          unless dependent.installed?
            test "brew", "fetch", "--retry", dependent.name
            next if steps.last.failed?
            conflicts = dependent.conflicts.map { |c| Formulary.factory(c.name) }.select(&:installed?)
            conflicts.each do |conflict|
              test "brew", "unlink", conflict.name
            end
            unless ARGV.include?("--fast")
              run_as_not_developer { test "brew", "install", dependent.name }
              next if steps.last.failed?
            end
          end
          if dependent.installed?
            test "brew", "linkage", "--test", dependent.name
            if testable_dependents.include? dependent
              test "brew", "test", "--verbose", dependent.name
            end
          end
        end
        after_linkage = Utils.popen_read("brew", "list").split("\n")
        installed_by_linkage = after_linkage - before_linkage
        test "brew", "uninstall", "--force", *installed_by_linkage unless installed_by_linkage.empty? || OS.mac?
        test "brew", "uninstall", "--force", formula_name
      end

      if formula.devel && formula.stable? \
         && !ARGV.include?("--HEAD") && !ARGV.include?("--fast") \
         && satisfied_requirements?(formula, :devel)
        test "brew", "fetch", "--retry", "--devel", *fetch_args
        run_as_not_developer do
          test "brew", "install", "--devel", formula_name, *shared_install_args
        end
        devel_install_passed = steps.last.passed?
        test "brew", "audit", "--devel", *audit_args
        if devel_install_passed
          test "brew", "test", "--devel", formula_name, *shared_test_args if formula.test_defined?
          test "brew", "uninstall", "--devel", "--force", formula_name
        end
      end
      test "brew", "uninstall", "--force", *unchanged_dependencies if unchanged_dependencies.any?
    end

    def homebrew
      @category = __method__
      return if @skip_homebrew
      test "brew", "tests"
      if @tap.core_tap?
        tests_args = ["--no-compat"]
        readall_args = ["--aliases"]
        if RUBY_VERSION.split(".").first.to_i >= 2
          tests_args << "--coverage" if ENV["TRAVIS"]
          readall_args << "--syntax"
        end
        test "brew", "tests", *tests_args
        test "brew", "readall", *readall_args
      else
        test "brew", "readall", @tap.name
      end
    end

    def cleanup_before
      @category = __method__
      return unless ARGV.include? "--cleanup"
      git "gc", "--auto"
      git "stash"
      git "am", "--abort"
      git "rebase", "--abort"
      git "reset", "--hard"
      git "checkout", "-f", "master"
      git "clean", "-ffdx"
      HOMEBREW_REPOSITORY.cd do
        safe_system "git", "reset", "--hard"
        safe_system "git", "checkout", "-f", "master"
        # This will uninstall all formulae, as long as
        # HOMEBREW_REPOSITORY == HOMEBREW_PREFIX, which is true on the test bots
        safe_system "git", "clean", "-ffdx", "--exclude=/Library/Taps/" unless ENV["HOMEBREW_RUBY"] == "1.8.7"
      end
      pr_locks = "#{@repository}/.git/refs/remotes/*/pr/*/*.lock"
      Dir.glob(pr_locks) { |lock| FileUtils.rm_rf lock }
    end

    def cleanup_after
      @category = __method__

      if @start_branch && !@start_branch.empty? && \
         (ARGV.include?("--cleanup") || @url || @hash)
        checkout_args = [@start_branch]
        checkout_args << "-f" if ARGV.include? "--cleanup"
        test "git", "checkout", *checkout_args
      end

      if ARGV.include? "--cleanup"
        test "git", "reset", "--hard"
        git "stash", "pop"
        test "brew", "cleanup", "--prune=7"
        git "gc", "--auto"
        test "git", "clean", "-ffdx"
        HOMEBREW_REPOSITORY.cd do
          safe_system "git", "reset", "--hard"
          Tap.names.each { |s| safe_system "brew", "untap", s if s != "homebrew/core" }
          safe_system "git", "clean", "-ffdx", "--exclude=/Library/Taps/"
        end
        if ARGV.include? "--local"
          FileUtils.rm_rf ENV["HOMEBREW_HOME"]
          FileUtils.rm_rf ENV["HOMEBREW_LOGS"]
        end
      end

      FileUtils.rm_rf @brewbot_root unless ARGV.include? "--keep-logs"
    end

    def test(*args)
      options = Hash === args.last ? args.pop : {}
      options[:repository] = @repository
      step = Step.new self, args, options
      step.run
      steps << step
      step
    end

    def check_results
      steps.all? do |step|
        case step.status
        when :passed  then true
        when :running then raise
        when :failed  then false
        end
      end
    end

    def formulae
      changed_formulae_dependents = {}

      @formulae.each do |formula|
        formula_dependencies = Utils.popen_read("brew", "deps", "--include-build", formula).split("\n")
        unchanged_dependencies = formula_dependencies - @formulae
        changed_dependences = formula_dependencies - unchanged_dependencies
        changed_dependences.each do |changed_formula|
          changed_formulae_dependents[changed_formula] ||= 0
          changed_formulae_dependents[changed_formula] += 1
        end
      end

      changed_formulae = changed_formulae_dependents.sort do |a1, a2|
        a2[1].to_i <=> a1[1].to_i
      end
      changed_formulae.map!(&:first)
      unchanged_formulae = @formulae - changed_formulae
      changed_formulae + unchanged_formulae
    end

    def head_only_tap?(formula)
      formula.head && formula.devel.nil? && formula.stable.nil? && formula.tap == "homebrew/homebrew-head-only"
    end

    def devel_only_tap?(formula)
      formula.devel && formula.stable.nil? && formula.tap == "homebrew/homebrew-devel-only"
    end

    def run
      cleanup_before
      begin
        download
        setup
        homebrew
        formulae.each do |f|
          formula(f)
        end
      ensure
        cleanup_after
      end
      check_results
    end
  end

  def test_ci_upload(tap)
    if ENV["GIT_BRANCH"]
      if ENV["GIT_BRANCH"].include?(":")
        # Docker automated build of a pull request.
        docker_user, docker_branch = ENV["GIT_BRANCH"].split(":")
      else
        # Docker automated build of master.
        docker_user = nil
        docker_branch = ENV["GIT_BRANCH"]
      end
      docker_sha1 = ENV["GIT_SHA1"]
    end

    jenkins = ENV["JENKINS_HOME"]
    job = ENV["UPSTREAM_JOB_NAME"]
    id = ENV["UPSTREAM_BUILD_ID"]
    raise "Missing Jenkins, Circle or Docker variables!" if (!jenkins || !job || !id) && !ENV["CIRCLE_BUILD_NUM"] && !docker_branch

    bintray_user = ENV["BINTRAY_USER"]
    bintray_key = ENV["BINTRAY_KEY"]
    if !bintray_user || !bintray_key
      raise "Missing BINTRAY_USER or BINTRAY_KEY variables!"
    end

    # Don't pass keys/cookies to subprocesses..
    ENV["BINTRAY_KEY"] = nil
    ENV["HUDSON_SERVER_COOKIE"] = nil
    ENV["JENKINS_SERVER_COOKIE"] = nil
    ENV["HUDSON_COOKIE"] = nil

    ARGV << "--verbose"
    ARGV << "--keep-old" if ENV["UPSTREAM_BOTTLE_KEEP_OLD"]
    ARGV << "--legacy" if ENV["UPSTREAM_BOTTLE_LEGACY"]

    if jenkins
      bottles = Dir["#{jenkins}/jobs/#{job}/configurations/axis-version/*/builds/#{id}/archive/*.bottle*.*"]
      return if bottles.empty?
      FileUtils.cp bottles, Dir.pwd, :verbose => true
    else
      return if Dir["*.bottle*.*"].empty?
    end

    if OS.mac?
      ENV["GIT_AUTHOR_NAME"] = ENV["GIT_COMMITTER_NAME"] = "BrewTestBot"
      ENV["GIT_AUTHOR_EMAIL"] = ENV["GIT_COMMITTER_EMAIL"] = "brew-test-bot@googlegroups.com"
    elsif OS.linux?
      ENV["GIT_AUTHOR_NAME"] = ENV["GIT_COMMITTER_NAME"] = "LinuxbrewTestBot"
      ENV["GIT_AUTHOR_EMAIL"] = ENV["GIT_COMMITTER_EMAIL"] = "testbot@linuxbrew.sh"
    end
    ENV["GIT_WORK_TREE"] = tap.path
    ENV["GIT_DIR"] = "#{ENV["GIT_WORK_TREE"]}/.git"

    pr = ENV["UPSTREAM_PULL_REQUEST"] || ENV["CIRCLE_PR_NUMBER"]
    number = ENV["UPSTREAM_BUILD_NUMBER"] || ENV["CIRCLE_BUILD_NUM"]

    quiet_system "git", "am", "--abort"
    quiet_system "git", "rebase", "--abort"
    safe_system "git", "checkout", "-f", "master"
    safe_system "git", "reset", "--hard", "origin/master"
    safe_system "brew", "update"

    if pr
      if ARGV.include?("--legacy")
        pull_pr = "https://github.com/Homebrew/legacy-homebrew/pull/#{pr}"
        safe_system "brew", "pull", "--clean", "--legacy", pull_pr
      else
        pull_pr = "#{tap.default_remote}/pull/#{pr}"
        safe_system "brew", "pull", "--clean", pull_pr
      end
    elsif docker_sha1
      url = "https://github.com/#{docker_user}/homebrew-#{tap.repo}/commit/#{docker_sha1}"
      safe_system "brew", "pull", "--clean", url
    end

    bottle_args = ["--merge", "--write", *Dir["*.bottle.rb"]]
    bottle_args << "--keep-old" if ARGV.include? "--keep-old"
    system "brew", "bottle", *bottle_args

    project = OS.mac? ? "homebrew" : "linuxbrew"
    remote = "git@github.com:#{ENV["GIT_AUTHOR_NAME"]}/homebrew-#{tap.repo}.git"
    tag = docker_branch ? "pr-#{docker_user}-#{docker_branch}" : pr ? "pr-#{pr}" : "testing-#{number}"

    bintray_org = project
    bintray_repo = Bintray.repository(tap)
    bintray_repo_url = "https://api.bintray.com/packages/#{bintray_org}/#{bintray_repo}"
    formula_packaged = {}

    Dir.glob("*.bottle*.tar.gz") do |filename|
      formula_name, canonical_formula_name = bottle_resolve_formula_names filename
      formula = Formulary.factory canonical_formula_name
      version = formula.pkg_version
      bintray_package = Bintray.package formula_name

      if system "curl", "-I", "--silent", "--fail", "--output", "/dev/null",
                "#{BottleSpecification::DEFAULT_DOMAIN}/#{bintray_repo}/#{filename}"
        raise <<-EOS.undent
          #{filename} is already published. Please remove it manually from
          https://bintray.com/#{bintray_org}/#{bintray_repo}/#{bintray_package}/view#files
        EOS
      end

      unless formula_packaged[formula_name]
        package_url = "#{bintray_repo_url}/#{bintray_package}"
        unless system "curl", "--silent", "--fail", "--output", "/dev/null", package_url
          package_blob = <<-EOS.undent
            {"name": "#{bintray_package}",
             #{'"licenses":["BSD 2-Clause"], "vcs_url":"https://github.com/Linuxbrew/linuxbrew.git",' if OS.linux?}
             "public_download_numbers": true,
             "public_stats": true}
          EOS
          curl "--silent", "--fail", "-u#{bintray_user}:#{bintray_key}",
               "-H", "Content-Type: application/json",
               "-d", package_blob, bintray_repo_url
          puts
        end
        formula_packaged[formula_name] = true
      end

      content_url = "https://api.bintray.com/content/#{bintray_org}"
      content_url += "/#{bintray_repo}/#{bintray_package}/#{version}/#{filename}"
      content_url += "?override=1"
      curl "--silent", "--fail", "-u#{bintray_user}:#{bintray_key}",
           "-T", filename, content_url
      puts
    end

    safe_system "git", "tag", "--force", tag
    safe_system "git", "push", "--force", remote, "master:master", "refs/tags/#{tag}"
  end

  def sanitize_ARGV_and_ENV
    if Pathname.pwd == HOMEBREW_PREFIX && ARGV.include?("--cleanup")
      odie "cannot use --cleanup from HOMEBREW_PREFIX as it will delete all output."
    end

    ENV["HOMEBREW_DEVELOPER"] = "1"
    ENV["HOMEBREW_SANDBOX"] = "1"
    ENV["HOMEBREW_NO_EMOJI"] = "1"
    ENV["HOMEBREW_FAIL_LOG_LINES"] = "150"
    ENV["HOMEBREW_EXPERIMENTAL_FILTER_FLAGS_ON_DEPS"] = "1"

    if ENV["TRAVIS"]
      ARGV << "--verbose"
      ARGV << "--ci-master" if ENV["TRAVIS_PULL_REQUEST"] == "false"
      ENV["HOMEBREW_VERBOSE_USING_DOTS"] = "1"
    end

    if ARGV.include?("--ci-master") || ARGV.include?("--ci-pr") \
       || ARGV.include?("--ci-testing")
      ARGV << "--cleanup" if ENV["JENKINS_HOME"]
      ARGV << "--junit" << "--local"
    end
    if ARGV.include? "--ci-master"
      ARGV << "--fast"
    end

    if ARGV.include? "--local"
      ENV["HOMEBREW_HOME"] = ENV["HOME"] = "#{Dir.pwd}/home"
      mkdir_p ENV["HOME"]
      ENV["HOMEBREW_LOGS"] = "#{Dir.pwd}/logs"
    end
  end

  def test_bot
    sanitize_ARGV_and_ENV

    tap = resolve_test_tap
    # Tap repository if required, this is done before everything else
    # because Formula parsing and/or git commit hash lookup depends on it.
    # At the same time, make sure Tap is not a shallow clone.
    # bottle revision and bottle upload rely on full clone.
    safe_system "brew", "tap", tap.name, "--full"

    if ARGV.include? "--ci-upload"
      return test_ci_upload(tap)
    end

    tests = []
    any_errors = false
    skip_homebrew = ARGV.include?("--skip-homebrew")
    if ARGV.named.empty?
      # With no arguments just build the most recent commit.
      head_test = Test.new("HEAD", :tap => tap, :skip_homebrew => skip_homebrew)
      any_errors = !head_test.run
      tests << head_test
    else
      ARGV.named.each do |argument|
        test_error = false
        begin
          test = Test.new(argument, :tap => tap, :skip_homebrew => skip_homebrew)
          skip_homebrew = true
        rescue ArgumentError => e
          test_error = true
          ofail e.message
        else
          test_error = !test.run
          tests << test
        end
        any_errors ||= test_error
      end
    end

    if ARGV.include? "--junit"
      xml_document = REXML::Document.new
      xml_document << REXML::XMLDecl.new
      testsuites = xml_document.add_element "testsuites"

      tests.each do |test|
        testsuite = testsuites.add_element "testsuite"
        testsuite.add_attribute "name", "brew-test-bot.#{MacOS.cat}"
        testsuite.add_attribute "tests", test.steps.count

        test.steps.each do |step|
          testcase = testsuite.add_element "testcase"
          testcase.add_attribute "name", step.command_short
          testcase.add_attribute "status", step.status
          testcase.add_attribute "time", step.time

          if step.has_output?
            output = sanitize_output_for_xml(step.output)
            cdata = REXML::CData.new output

            if step.passed?
              elem = testcase.add_element "system-out"
            else
              elem = testcase.add_element "failure"
              elem.add_attribute "message", "#{step.status}: #{step.command.join(" ")}"
            end

            elem << cdata
          end
        end
      end

      open("brew-test-bot.xml", "w") do |xml_file|
        pretty_print_indent = 2
        xml_document.write(xml_file, pretty_print_indent)
      end
    end
  ensure
    if ARGV.include? "--clean-cache"
      HOMEBREW_CACHE.children.each(&:rmtree)
    else
      Dir.glob("*.bottle*.tar.gz") do |bottle_file|
        FileUtils.rm_f HOMEBREW_CACHE/bottle_file
      end
    end

    Homebrew.failed = any_errors
  end

  def sanitize_output_for_xml(output)
    unless output.empty?
      # Remove invalid XML CData characters from step output.
      if ruby_has_encoding?
        # This is the regex for valid XML chars, but only works in Ruby 2.0+
        # /[\x09\x0A\x0D\x20-\uD7FF\uE000-\uFFFD\u{10000}-\u{10FFFF}]/
        # For 1.9 compatibility, use the inverse of that, which stays under \u10000
        # invalid_xml_pat = /[\x00-\x08\x0B\x0C\x0E-\x1F\uD800-\uDFFF\uFFFE\uFFFF]/
        # But Ruby won't allow you to reference surrogates, so we have:
        invalid_xml_pat = /[\x00-\x08\x0B\x0C\x0E-\x1F\uFFFE\uFFFF]/
        output = output.gsub(invalid_xml_pat, "\uFFFD")
      else
        output = output.delete("\000\a\b\e\f\x2\x1f")
      end

      # Truncate to 1MB to avoid hitting CI limits
      if output.bytesize > MAX_STEP_OUTPUT_SIZE
        if ruby_has_encoding?
          binary_output = output.force_encoding("BINARY")
          output = binary_output.slice(-MAX_STEP_OUTPUT_SIZE, MAX_STEP_OUTPUT_SIZE)
          fix_encoding!(output)
        else
          output = output.slice(-MAX_STEP_OUTPUT_SIZE, MAX_STEP_OUTPUT_SIZE)
        end
        output = "truncated output to 1MB:\n" + output
      end
    end
    output
  end
end

