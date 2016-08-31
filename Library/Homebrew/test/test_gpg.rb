require "testing_env"
require "gpg"

class GpgTest < Homebrew::TestCase
  def setup
    skip "GPG Unavailable" unless Gpg.available?
    @dir = Pathname.new(mktmpdir)
  end

  def test_create_test_key
    Dir.chdir(@dir) do
      with_environment("HOME" => @dir) do
        shutup { Gpg.create_test_key(@dir) }
        assert_predicate @dir/".gnupg/secring.gpg", :exist?
      end
    end
  ensure
    @dir.rmtree
  end
end
