require "helper/integration_command_test_case"

class IntegrationCommandTestOutdated < IntegrationCommandTestCase
  def test_outdated
    setup_test_formula "testball"
    (HOMEBREW_CELLAR/"testball/0.0.1/foo").mkpath

    if ARGV.verbose?
      assert_equal "testball (0.0.1) < 0.1", cmd("outdated")
    else
      assert_equal "testball", cmd("outdated")
    end
  end
end
