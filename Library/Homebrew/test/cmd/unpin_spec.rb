describe "brew unpin", :integration_test do
  it "unpins a Formula's version" do
    setup_test_formula "testball"
    (HOMEBREW_CELLAR/"testball/0.0.1/foo").mkpath

    shutup do
      expect { brew "pin", "testball" }.to be_a_success
      expect { brew "unpin", "testball" }.to be_a_success
      expect { brew "upgrade" }.to be_a_success
    end

    expect(HOMEBREW_CELLAR/"testball/0.1").to be_a_directory
  end
end
