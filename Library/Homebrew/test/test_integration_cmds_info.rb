require "integration_cmds_tests"

class IntegrationCommandTestInfo < IntegrationCommandTests
  def test_info
    setup_test_formula "testball"

    assert_match "testball: stable 0.1",
                 cmd("info", "testball")
  end
end
