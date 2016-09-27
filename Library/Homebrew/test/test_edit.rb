require "helper/integration_command_test_case"

class IntegrationCommandTestEdit < IntegrationCommandTestCase
  def test_edit
    (HOMEBREW_REPOSITORY/".git").mkpath
    setup_test_formula "testball"

    assert_match "# something here",
                 cmd("edit", "testball", "HOMEBREW_EDITOR" => "/bin/cat")
  end
end
