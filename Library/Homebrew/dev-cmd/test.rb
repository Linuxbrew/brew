#:  * `test` [`--devel`|`--HEAD`] [`--debug`] [`--keep-tmp`] <formula>:
#:    Most formulae provide a test method. `brew test` <formula> runs this
#:    test method. There is no standard output or return code, but it should
#:    generally indicate to the user if something is wrong with the installed
#:    formula.
#:
#:    To test the development or head version of a formula, use `--devel` or
#:    `--HEAD`.
#:
#:    If `--debug` is passed and the test fails, an interactive debugger will be
#:    launched with access to IRB or a shell inside the temporary test directory.
#:
#:    If `--keep-tmp` is passed, the temporary files created for the test are
#:    not deleted.
#:
#:    Example: `brew install jruby && brew test jruby`

require "extend/ENV"
require "formula_assertions"
require "sandbox"
require "timeout"

module Homebrew
  module_function

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

      puts "Testing #{f.full_name}"

      env = ENV.to_hash

      begin
        args = %W[
          #{RUBY_PATH}
          -W0
          -I #{HOMEBREW_LOAD_PATH}
          --
          #{HOMEBREW_LIBRARY_PATH}/test.rb
          #{f.path}
        ].concat(ARGV.options_only)

        if f.head?
          args << "--HEAD"
        elsif f.devel?
          args << "--devel"
        end

        Sandbox.print_sandbox_message if Sandbox.test?

        Utils.safe_fork do
          if Sandbox.test?
            sandbox = Sandbox.new
            f.logs.mkpath
            sandbox.record_log(f.logs/"test.sandbox.log")
            sandbox.allow_write_temp_and_cache
            sandbox.allow_write_log(f)
            sandbox.allow_write_xcode
            sandbox.allow_write_path(HOMEBREW_PREFIX/"var/cache")
            sandbox.allow_write_path(HOMEBREW_PREFIX/"var/log")
            sandbox.allow_write_path(HOMEBREW_PREFIX/"var/run")
            sandbox.exec(*args)
          else
            exec(*args)
          end
        end
      rescue Assertions::FailedAssertion => e
        ofail "#{f.full_name}: failed"
        puts e.message
      rescue Exception => e
        ofail "#{f.full_name}: failed"
        puts e, e.backtrace
      ensure
        ENV.replace(env)
      end
    end
  end
end
