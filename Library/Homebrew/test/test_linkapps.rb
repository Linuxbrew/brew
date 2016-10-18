require "helper/integration_command_test_case"

class IntegrationCommandTestLinkapps < IntegrationCommandTestCase
  def test_linkapps
    home_dir = Pathname.new(mktmpdir)
    (home_dir/"Applications").mkpath

    setup_test_formula "testball"

    source_dir = HOMEBREW_CELLAR/"testball/0.1/TestBall.app"
    source_dir.mkpath
    assert_match "Linking: #{source_dir}",
      cmd("linkapps", "--local", "HOME" => home_dir)
  end
end
