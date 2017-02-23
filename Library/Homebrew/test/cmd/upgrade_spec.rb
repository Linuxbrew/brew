describe "brew upgrade", :integration_test do
  it "upgrades a Formula to the latest version" do
    setup_test_formula "testball"
    (HOMEBREW_CELLAR/"testball/0.0.1/foo").mkpath

    shutup do
      expect { brew "upgrade" }.to be_a_success
    end

    expect(HOMEBREW_CELLAR/"testball/0.1").to be_a_directory
  end
end
