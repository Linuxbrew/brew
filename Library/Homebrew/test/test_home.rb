require "helper/integration_command_test_case"

class IntegrationCommandTestHome < IntegrationCommandTestCase
  def test_home
    setup_test_formula "testball"

    assert_equal HOMEBREW_WWW,
                 cmd("home", "HOMEBREW_BROWSER" => "echo")
    assert_equal Formula["testball"].homepage,
                 cmd("home", "testball", "HOMEBREW_BROWSER" => "echo")
  end
end
