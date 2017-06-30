module Homebrew
  module Assertions
    require "test/unit/assertions"
    include ::Test::Unit::Assertions

    # Custom name here for cross-version compatibility.
    # In Ruby 2.0, Test::Unit::Assertions raise a MiniTest::Assertion,
    # but they raise Test::Unit::AssertionFailedError in 2.3.
    # If neither is defined, this might be a completely different
    # version of Ruby.
    if defined?(MiniTest::Assertion)
      AssertionFailed = MiniTest::Assertion
    elsif defined?(Test::Unit::AssertionFailedError)
      AssertionFailed = Test::Unit::AssertionFailedError
    else
      raise NameError, "Unable to find an assertion class for this version of Ruby (#{RUBY_VERSION})"
    end

    # Returns the output of running cmd, and asserts the exit status
    def shell_output(cmd, result = 0)
      ohai cmd
      output = `#{cmd}`
      assert_equal result, $CHILD_STATUS.exitstatus
      output
    end

    # Returns the output of running the cmd with the optional input, and
    # optionally asserts the exit status
    def pipe_output(cmd, input = nil, result = nil)
      ohai cmd
      output = IO.popen(cmd, "w+") do |pipe|
        pipe.write(input) unless input.nil?
        pipe.close_write
        pipe.read
      end
      assert_equal result, $CHILD_STATUS.exitstatus unless result.nil?
      output
    end
  end
end
