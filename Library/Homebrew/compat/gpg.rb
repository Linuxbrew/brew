require "utils"

module Gpg
  module_function

  def executable
    odeprecated "Gpg.executable", 'which "gpg"'
    which "gpg"
  end

  def available?
    odeprecated "Gpg.available?", 'which "gpg"'
    File.executable?(executable.to_s)
  end

  def create_test_key(_)
    odeprecated "Gpg.create_test_key"
  end

  def cleanup_test_processes!
    odeprecated "Gpg.cleanup_test_processes!"
  end

  def test(_)
    odeprecated "Gpg.test"
  end
end
