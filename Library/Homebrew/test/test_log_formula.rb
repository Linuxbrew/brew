require "helper/integration_command_test_case"

class IntegrationCommandTestLogFormula < IntegrationCommandTestCase
  def test_log_formula
    core_tap = CoreTap.new
    setup_test_formula "testball"

    core_tap.path.cd do
      shutup do
        system "git", "init"
        system "git", "add", "--all"
        system "git", "commit", "-m", "This is a test commit for Testball"
      end
    end

    core_tap_url = "file://#{core_tap.path}"
    shallow_tap = Tap.fetch("homebrew", "shallow")
    shutup do
      system "git", "clone", "--depth=1", core_tap_url, shallow_tap.path
    end

    assert_match "This is a test commit for Testball",
                 cmd("log", "#{shallow_tap}/testball")
    assert_predicate shallow_tap.path/".git/shallow", :exist?,
                     "A shallow clone should have been created."
  end
end
