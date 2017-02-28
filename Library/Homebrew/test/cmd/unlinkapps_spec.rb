describe "brew unlinkapps", :integration_test do
  let(:home_dir) { mktmpdir }
  let(:apps_dir) { home_dir/"Applications" }

  it "unlinks symlinked applications" do
    apps_dir.mkpath

    setup_test_formula "testball"

    source_app = HOMEBREW_CELLAR/"testball/0.1/TestBall.app"
    source_app.mkpath

    FileUtils.ln_s source_app, apps_dir/"TestBall.app"

    expect { brew "unlinkapps", "--local", "HOME" => home_dir }
      .to output(%r{Unlinking: #{Regexp.escape(apps_dir)}/TestBall.app}).to_stdout
      .and output(/`brew unlinkapps` has been deprecated/).to_stderr
      .and be_a_success
  end
end
