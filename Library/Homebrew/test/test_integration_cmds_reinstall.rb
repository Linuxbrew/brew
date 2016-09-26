require "integration_cmds_tests"

class IntegrationCommandTestReinstall < IntegrationCommandTests
  def test_reinstall
    setup_test_formula "testball"

    cmd("install", "testball", "--with-foo")
    foo_dir = HOMEBREW_CELLAR/"testball/0.1/foo"
    assert foo_dir.exist?
    foo_dir.rmtree
    assert_match "Reinstalling testball with --with-foo",
      cmd("reinstall", "testball")
    assert foo_dir.exist?
  end
end
