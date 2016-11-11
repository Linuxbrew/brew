require "helper/integration_command_test_case"
require "cmd/uninstall"

class UninstallTests < Homebrew::TestCase
  def test_check_for_testball_f2s_when_developer
    refute_predicate Homebrew, :should_check_for_dependents?
  end

  def test_check_for_dependents_when_not_developer
    run_as_not_developer do
      assert_predicate Homebrew, :should_check_for_dependents?
    end
  end

  def test_check_for_dependents_when_ignore_dependencies
    ARGV << "--ignore-dependencies"
    run_as_not_developer do
      refute_predicate Homebrew, :should_check_for_dependents?
    end
  ensure
    ARGV.delete("--ignore-dependencies")
  end
end

class IntegrationCommandTestUninstall < IntegrationCommandTestCase
  def test_uninstall
    cmd("install", testball)
    assert_match "Uninstalling testball", cmd("uninstall", "--force", testball)
  end
end
