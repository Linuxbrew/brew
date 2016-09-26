require "helper/integration_command_test_case"

class IntegrationCommandTestMissing < IntegrationCommandTestCase
  def test_missing
    setup_test_formula "foo"
    setup_test_formula "bar"

    (HOMEBREW_CELLAR/"bar/1.0").mkpath
    assert_match "foo", cmd("missing")
  end
end
