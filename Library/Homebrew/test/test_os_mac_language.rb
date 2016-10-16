require "testing_env"
require "locale"
require "os/mac"

class OSMacLanguageTests < Homebrew::TestCase
  def test_languages_format
    OS::Mac.languages.each do |language|
      assert_nothing_raised do
        Locale.parse(language)
      end
    end
  end

  def test_language_format
    assert_nothing_raised do
      Locale.parse(OS::Mac.language)
    end
  end
end
