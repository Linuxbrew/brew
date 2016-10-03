require "testing_env"
require "os/mac"

class OSMacLanguageTests < Homebrew::TestCase
  LANGUAGE_REGEX = /\A[a-z]{2}(-[A-Z]{2})?(-[A-Z][a-z]{3})?\Z/

  def test_languages_format
    OS::Mac.languages.each do |language|
      assert_match LANGUAGE_REGEX, language
    end
  end

  def test_language_format
    assert_match LANGUAGE_REGEX, OS::Mac.language
  end
end
