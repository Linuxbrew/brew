describe "brew upgrade", :integration_test do
  it "upgrades a Formula to the latest version" do
    setup_test_formula "testball"
    (HOMEBREW_CELLAR/"testball/0.0.1/foo").mkpath

    expect { brew "upgrade" }.to be_a_success

    expect(HOMEBREW_CELLAR/"testball/0.1").to be_a_directory
  end

  it "upgrades a Formula and cleans up old versions when `--cleanup` is passed" do
    setup_test_formula "testball"
    (HOMEBREW_CELLAR/"testball/0.0.1/foo").mkpath

    expect { brew "upgrade", "--cleanup" }.to be_a_success

    expect(HOMEBREW_CELLAR/"testball/0.1").to be_a_directory
    expect(HOMEBREW_CELLAR/"testball/0.0.1").not_to exist
  end
end
