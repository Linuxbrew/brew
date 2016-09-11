require "testing_env"
require "os/mac"

class OSMacLanguageTests < Homebrew::TestCase
  def test_language_format
    assert_match(/\A[a-z]{2}(-[A-Z]{2})?\Z/, OS::Mac.language)
  end
end
