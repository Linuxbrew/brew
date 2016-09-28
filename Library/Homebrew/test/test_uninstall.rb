require "helper/integration_command_test_case"

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

  def test_uninstall
    cmd("install", testball)
    assert_match "Uninstalling testball", cmd("uninstall", "--force", testball)
  end

  def test_uninstall_leaving_dependents
    cmd("install", "testball_f2")
    assert_match "Refusing to uninstall", cmd_fail("uninstall", "testball_f1")
    assert_match "Uninstalling #{Formulary.factory(@f2_path).rack}",
      cmd("uninstall", "testball_f2")
  end

  def test_uninstall_force_leaving_dependents
    cmd("install", "testball_f2")
    assert_match "Refusing to uninstall",
      cmd_fail("uninstall", "testball_f1", "--force")
    assert_match "Uninstalling testball_f2",
      cmd("uninstall", "testball_f2", "--force")
  end

  def test_uninstall_dependent_first
    cmd("install", "testball_f2")
    assert_match "Uninstalling #{Formulary.factory(@f1_path).rack}",
      cmd("uninstall", "testball_f2", "testball_f1")
  end

  def test_uninstall_dependent_last
    cmd("install", "testball_f2")
    assert_match "Uninstalling #{Formulary.factory(@f2_path).rack}",
      cmd("uninstall", "testball_f1", "testball_f2")
  end
end
