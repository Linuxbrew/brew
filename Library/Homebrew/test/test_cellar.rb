require "helper/integration_command_test_case"

class IntegrationCommandTestCellar < IntegrationCommandTestCase
  def test_cellar
    assert_equal HOMEBREW_CELLAR.to_s,
                 cmd("--cellar")
  end
end
