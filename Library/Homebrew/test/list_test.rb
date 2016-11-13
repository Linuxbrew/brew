require "testing_env"

class IntegrationCommandTestList < IntegrationCommandTestCase
  def test_list
    formulae = %w[bar foo qux]
    formulae.each do |f|
      (HOMEBREW_CELLAR/"#{f}/1.0/somedir").mkpath
    end

    assert_equal formulae.join("\n"),
                 cmd("list")
  end
end
