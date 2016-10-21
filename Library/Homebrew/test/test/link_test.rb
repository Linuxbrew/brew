require "helper/integration_command_test_case"

class IntegrationCommandTestLink < IntegrationCommandTestCase
  def test_link
    assert_match "This command requires a keg argument", cmd_fail("link")

    setup_test_formula "testball1"
    cmd("install", "testball1")
    cmd("link", "testball1")

    cmd("unlink", "testball1")
    assert_match "Would link", cmd("link", "--dry-run", "testball1")
    assert_match "Would remove",
      cmd("link", "--dry-run", "--overwrite", "testball1")
    assert_match "Linking", cmd("link", "testball1")

    setup_test_formula "testball2", <<-EOS.undent
      keg_only "just because"
    EOS
    cmd("install", "testball2")
    assert_match "testball2 is keg-only", cmd("link", "testball2")
  end
end
