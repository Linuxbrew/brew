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
  def setup
    super
    @f1_path = setup_test_formula "testball_f1", <<-CONTENT
      def install
        FileUtils.touch prefix/touch("hello")
      end
    CONTENT
    @f2_path = setup_test_formula "testball_f2", <<-CONTENT
      depends_on "testball_f1"

      def install
        FileUtils.touch prefix/touch("hello")
      end
    CONTENT
  end

  def f1
    Formulary.factory(@f1_path)
  end

  def f2
    Formulary.factory(@f2_path)
  end

  def test_uninstall
    cmd("install", "testball_f2")
    run_as_not_developer do
      assert_match "Refusing to uninstall",
        cmd_fail("uninstall", "testball_f1")
      refute_empty f1.installed_kegs

      assert_match "Uninstalling #{f2.rack}",
        cmd("uninstall", "testball_f2")
      assert_empty f2.installed_kegs

      assert_match "Uninstalling #{f1.rack}",
        cmd("uninstall", "testball_f1")
      assert_empty f1.installed_kegs
    end
  end
end
