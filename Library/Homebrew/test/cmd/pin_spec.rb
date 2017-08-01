describe "brew pin", :integration_test do
  it "pins a Formula's version" do
    setup_test_formula "testball"
    (HOMEBREW_CELLAR/"testball/0.0.1/foo").mkpath

    expect { brew "pin", "testball" }.to be_a_success
    expect { brew "upgrade" }.to be_a_success

    expect(HOMEBREW_CELLAR/"testball/0.1").not_to be_a_directory
  end
end
