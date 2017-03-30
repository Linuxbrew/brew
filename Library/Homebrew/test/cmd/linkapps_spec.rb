describe "brew linkapps", :integration_test do
  let(:home_dir) { mktmpdir }
  let(:apps_dir) { home_dir/"Applications" }

  it "symlinks applications" do
    apps_dir.mkpath

    setup_test_formula "testball"

    source_app = HOMEBREW_CELLAR/"testball/0.1/TestBall.app"
    source_app.mkpath

    expect { brew "linkapps", "--local", "HOME" => home_dir }
      .to output(/Linking: #{Regexp.escape(source_app)}/).to_stdout
      .and output(/`brew linkapps` has been deprecated/).to_stderr
      .and be_a_success

    expect(apps_dir/"TestBall.app").to be_a_symlink
  end
end
