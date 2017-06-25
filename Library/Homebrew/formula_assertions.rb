module Homebrew
  module Assertions
    require "test/unit/assertions"
    include ::Test::Unit::Assertions

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
