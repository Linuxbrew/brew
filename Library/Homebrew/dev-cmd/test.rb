#:  * `test` [`--devel`|`--HEAD`] [`--debug`] [`--keep-tmp`] <formulae>:
#:    Run the test method provided by a formula.
#:    There is no standard output or return code, but generally it should notify the
#:    user if something is wrong with the installed formula.
#:
#:    To test the development or head version of a formula, use `--devel` or
#:    `--HEAD`.
#:
#:    If `--debug` (or `-d`) is passed and the test fails, an interactive debugger will be
#:    launched with access to IRB or a shell inside the temporary test directory.
#:
#:    If `--keep-tmp` is passed, the temporary files created for the test are
#:    not deleted.
#:
#:    *Example:* `brew install jruby && brew test jruby`

require "extend/ENV"
require "formula_assertions"
require "sandbox"
require "timeout"

module Homebrew
  module_function

  def test_args
    Homebrew::CLI::Parser.new do
      usage_banner <<~EOS
        `test` [<options>] <formulae>

        Run the test method provided by an installed formula.
        There is no standard output or return code, but generally it should notify the
        user if something is wrong with the installed formula.

        *Example:* `brew install jruby && brew test jruby`
      EOS
      switch "--devel",
        description: "Test the development version of a formula."
      switch "--HEAD",
        description: "Test the head version of a formula."
      switch "--keep-tmp",
        description: "Keep the temporary files created for the test."
      switch :verbose
      switch :debug
    end
  end

  def test
    raise FormulaUnspecifiedError if ARGV.named.empty?

    ARGV.resolved_formulae.each do |f|
      # Cannot test uninstalled formulae
      unless f.installed?
        ofail "Testing requires the latest version of #{f.full_name}"
        next
      end

      # Cannot test formulae without a test method
      unless f.test_defined?
        ofail "#{f.full_name} defines no test"
        next
      end

      # Don't test unlinked formulae
      if !ARGV.force? && !f.keg_only? && !f.linked?
        ofail "#{f.full_name} is not linked"
        next
      end

      # Don't test formulae missing test dependencies
      missing_test_deps = f.recursive_dependencies do |_, dependency|
        Dependency.prune if dependency.installed?
        next if dependency.test?

        Dependency.prune if dependency.optional?
        Dependency.prune if dependency.build?
      end.map(&:to_s)
      unless missing_test_deps.empty?
        ofail "#{f.full_name} is missing test dependencies: #{missing_test_deps.join(" ")}"
        next
      end

      puts "Testing #{f.full_name}"

      env = ENV.to_hash

      begin
        args = %W[
          #{RUBY_PATH}
          -W0
          -I #{$LOAD_PATH.join(File::PATH_SEPARATOR)}
          --
          #{HOMEBREW_LIBRARY_PATH}/test.rb
          #{f.path}
        ].concat(ARGV.options_only)

        if f.head?
          args << "--HEAD"
        elsif f.devel?
          args << "--devel"
        end

        Utils.safe_fork do
          if Sandbox.test?
            sandbox = Sandbox.new
            f.logs.mkpath
            sandbox.record_log(f.logs/"test.sandbox.log")
            sandbox.allow_write_temp_and_cache
            sandbox.allow_write_log(f)
            sandbox.allow_write_xcode
            sandbox.allow_write_path(HOMEBREW_PREFIX/"var/cache")
            sandbox.allow_write_path(HOMEBREW_PREFIX/"var/homebrew/locks")
            sandbox.allow_write_path(HOMEBREW_PREFIX/"var/log")
            sandbox.allow_write_path(HOMEBREW_PREFIX/"var/run")
            sandbox.exec(*args)
          else
            exec(*args)
          end
        end
      rescue Exception => e # rubocop:disable Lint/RescueException
        ofail "#{f.full_name}: failed"
        puts e, e.backtrace
      ensure
        ENV.replace(env)
      end
    end
  end
end
