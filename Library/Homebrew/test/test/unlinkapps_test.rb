require "helper/integration_command_test_case"

class IntegrationCommandTestUnlinkapps < IntegrationCommandTestCase
  def test_unlinkapps
    home_dir = Pathname.new(mktmpdir)
    apps_dir = home_dir/"Applications"
    apps_dir.mkpath

    setup_test_formula "testball"

    source_app = (HOMEBREW_CELLAR/"testball/0.1/TestBall.app")
    source_app.mkpath

    FileUtils.ln_s source_app, "#{apps_dir}/TestBall.app"

    assert_match "Unlinking: #{apps_dir}/TestBall.app",
      cmd("unlinkapps", "--local", "HOME" => home_dir)
  end
end
