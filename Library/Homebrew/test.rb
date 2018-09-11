old_trap = trap("INT") { exit! 130 }

require "global"
require "extend/ENV"
require "timeout"
require "debrew"
require "formula_assertions"
require "fcntl"
require "socket"

TEST_TIMEOUT_SECONDS = 5 * 60

begin
  error_pipe = UNIXSocket.open(ENV["HOMEBREW_ERROR_PIPE"], &:recv_io)
  error_pipe.fcntl(Fcntl::F_SETFD, Fcntl::FD_CLOEXEC)

  ENV.extend(Stdenv)
  ENV.setup_build_environment

  trap("INT", old_trap)

  formula = ARGV.resolved_formulae.first
  formula.extend(Homebrew::Assertions)
  formula.extend(Debrew::Formula) if ARGV.debug?

  # tests can also return false to indicate failure
  Timeout.timeout TEST_TIMEOUT_SECONDS do
    raise "test returned false" if formula.run_test == false
  end
rescue Exception => e # rubocop:disable Lint/RescueException
  error_pipe.puts e.to_json
  error_pipe.close
  exit! 1
end
