require "helper/integration_command_test_case"

class IntegrationCommandTestMigrate < IntegrationCommandTestCase
  def test_migrate
    setup_test_formula "testball1"
    setup_test_formula "testball2"
    assert_match "Invalid usage", cmd_fail("migrate")
    assert_match "No available formula with the name \"testball\"",
      cmd_fail("migrate", "testball")
    assert_match "testball1 doesn't replace any formula",
      cmd_fail("migrate", "testball1")

    install_and_rename_coretap_formula "testball1", "testball2"
    assert_match "Migrating testball1 to testball2", cmd("migrate", "testball1")
    (HOMEBREW_CELLAR/"testball1").unlink
    assert_match "Error: No such keg", cmd_fail("migrate", "testball1")
  end
end
