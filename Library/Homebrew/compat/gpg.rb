
module Gpg
  module_function

  def executable
    odisabled "Gpg.executable", 'which "gpg"'
  end

  def available?
    odisabled "Gpg.available?", 'which "gpg"'
  end

  def create_test_key(_)
    odisabled "Gpg.create_test_key"
  end

  def cleanup_test_processes!
    odisabled "Gpg.cleanup_test_processes!"
  end

  def test(_)
    odisabled "Gpg.test"
  end
end
