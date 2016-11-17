require "testing_env"

class IntegrationCommandTestSh < IntegrationCommandTestCase
  def test_sh
    assert_match "Your shell has been configured",
                 cmd("sh", "SHELL" => which("true"))
  end
end
