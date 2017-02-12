require "testing_env"
require "gpg"

class GpgTest < Homebrew::TestCase
  def setup
    super
    skip "GPG Unavailable" unless Gpg.available?
    @dir = Pathname.new(mktmpdir)
  end

  def test_create_test_key
    Dir.chdir(@dir) do
      ENV["HOME"] = @dir
      shutup { Gpg.create_test_key(@dir) }
      assert_predicate @dir/".gnupg/secring.gpg", :exist?
    end
  end
end
