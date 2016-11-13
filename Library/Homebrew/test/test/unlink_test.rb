require "testing_env"

class IntegrationCommandTestUnlink < IntegrationCommandTestCase
  def test_unlink
    setup_test_formula "testball"

    cmd("install", "testball")
    assert_match "Would remove", cmd("unlink", "--dry-run", "testball")
  end
end
