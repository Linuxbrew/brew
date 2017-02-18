require "testing_env"

class IntegrationCommandTestReinstall < IntegrationCommandTestCase
  def test_reinstall
    setup_test_formula "testball"

    cmd("install", "testball", "--with-foo")
    foo_dir = HOMEBREW_CELLAR/"testball/0.1/foo"
    assert foo_dir.exist?
    foo_dir.rmtree
    assert_match "Reinstalling testball --with-foo",
      cmd("reinstall", "testball")
    assert foo_dir.exist?
  end

  def test_reinstall_with_invalid_option
    setup_test_formula "testball"

    cmd("install", "testball", "--with-foo")

    assert_match "testball: this formula has no --with-fo option so it will be ignored!",
      cmd("reinstall", "testball", "--with-fo")
  end
end
