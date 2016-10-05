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

  def f1
    Formulary.factory(@f1_path)
  end

  def f2
    Formulary.factory(@f2_path)
  end

  def test_uninstall
    cmd("install", testball)
    assert_match "Uninstalling testball", cmd("uninstall", "--force", testball)
    assert_empty Formulary.factory(testball).installed_kegs
  end

  def test_uninstall_with_unrelated_missing_deps_in_tab
    setup_test_formula "testball"
    run_as_not_developer do
      cmd("install", testball)
      cmd("install", "testball_f2")
      cmd("uninstall", "--ignore-dependencies", "testball_f1")
      cmd("uninstall", testball)
    end
  end

  def test_uninstall_with_unrelated_missing_deps_not_in_tab
    setup_test_formula "testball"
    run_as_not_developer do
      cmd("install", testball)
      cmd("install", "testball_f2")

      f2_keg = f2.installed_kegs.first
      f2_tab = Tab.for_keg(f2_keg)
      f2_tab.runtime_dependencies = nil
      f2_tab.write

      cmd("uninstall", "--ignore-dependencies", "testball_f1")
      cmd("uninstall", testball)
    end
  end

  def test_uninstall_leaving_dependents
    cmd("install", "testball_f2")
    run_as_not_developer do
      assert_match "Refusing to uninstall",
        cmd_fail("uninstall", "testball_f1")
      refute_empty f1.installed_kegs
      assert_match "Uninstalling #{f2.rack}",
        cmd("uninstall", "testball_f2")
      assert_empty f2.installed_kegs
    end
  end

  def test_uninstall_leaving_dependents_no_runtime_dependencies_in_tab
    cmd("install", "testball_f2")

    f2_keg = f2.installed_kegs.first
    f2_tab = Tab.for_keg(f2_keg)
    f2_tab.runtime_dependencies = nil
    f2_tab.write

    run_as_not_developer do
      assert_match "Refusing to uninstall",
        cmd_fail("uninstall", "testball_f1")
      refute_empty f1.installed_kegs
      assert_match "Uninstalling #{f2.rack}",
        cmd("uninstall", "testball_f2")
      assert_empty f2.installed_kegs
    end
  end

  def test_uninstall_force_leaving_dependents
    cmd("install", "testball_f2")
    run_as_not_developer do
      assert_match "Refusing to uninstall",
        cmd_fail("uninstall", "testball_f1", "--force")
      refute_empty f1.installed_kegs
      assert_match "Uninstalling testball_f2",
        cmd("uninstall", "testball_f2", "--force")
      assert_empty f2.installed_kegs
    end
  end

  def test_uninstall_ignore_dependencies_leaving_dependents
    cmd("install", "testball_f2")
    run_as_not_developer do
      assert_match "Uninstalling #{f1.rack}",
        cmd("uninstall", "testball_f1", "--ignore-dependencies")
      assert_empty f1.installed_kegs
    end
  end

  def test_uninstall_leaving_dependents_developer
    cmd("install", "testball_f2")
    assert_match "Uninstalling #{f1.rack}",
      cmd("uninstall", "testball_f1")
    assert_empty f1.installed_kegs
  end

  def test_uninstall_dependent_first
    cmd("install", "testball_f2")
    run_as_not_developer do
      assert_match "Uninstalling #{f1.rack}",
        cmd("uninstall", "testball_f2", "testball_f1")
      assert_empty f1.installed_kegs
    end
  end

  def test_uninstall_dependent_last
    cmd("install", "testball_f2")
    run_as_not_developer do
      assert_match "Uninstalling #{f2.rack}",
        cmd("uninstall", "testball_f1", "testball_f2")
      assert_empty f2.installed_kegs
    end
  end
end
