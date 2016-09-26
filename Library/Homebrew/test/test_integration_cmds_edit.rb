require "integration_cmds_tests"

class IntegrationCommandTestEdit < IntegrationCommandTests
  def test_edit
    (HOMEBREW_REPOSITORY/".git").mkpath
    setup_test_formula "testball"

    assert_match "# something here",
                 cmd("edit", "testball", "HOMEBREW_EDITOR" => "/bin/cat")
  end
end
