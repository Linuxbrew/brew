require "helper/integration_command_test_case"

class IntegrationCommandTestInstall < IntegrationCommandTestCase
  def test_install
    setup_test_formula "testball1"
    assert_match "Specify `--HEAD`", cmd_fail("install", "testball1", "--head")
    assert_match "No head is defined", cmd_fail("install", "testball1", "--HEAD")
    assert_match "No devel block", cmd_fail("install", "testball1", "--devel")
    assert_match "#{HOMEBREW_CELLAR}/testball1/0.1", cmd("install", "testball1")
    assert_match "testball1-0.1 already installed", cmd("install", "testball1")
    assert_match "MacRuby is not packaged", cmd_fail("install", "macruby")
    assert_match "No available formula", cmd_fail("install", "formula")
    assert_match "This similarly named formula was found",
      cmd_fail("install", "testball")

    setup_test_formula "testball2"
    assert_match "These similarly named formulae were found",
      cmd_fail("install", "testball")

    install_and_rename_coretap_formula "testball1", "testball2"
    assert_match "testball1 already installed, it's just not migrated",
      cmd("install", "testball2")
  end

  def test_install_with_invalid_option
    setup_test_formula "testball1"
    assert_match "testball1: this formula has no --with-fo option so it will be ignored!",
      cmd("install", "testball1", "--with-fo")
  end
end
