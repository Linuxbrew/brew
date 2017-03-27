describe "brew outdated", :integration_test do
  context "quiet output" do
    it "prints outdated Formulae" do
      setup_test_formula "testball"
      (HOMEBREW_CELLAR/"testball/0.0.1/foo").mkpath

      expect { brew "outdated" }
        .to output("testball\n").to_stdout
        .and not_to_output.to_stderr
        .and be_a_success
    end
  end

  context "verbose output" do
    it "prints out the installed and newer versions" do
      setup_test_formula "testball"
      (HOMEBREW_CELLAR/"testball/0.0.1/foo").mkpath

      expect { brew "outdated", "--verbose" }
        .to output("testball (0.0.1) < 0.1\n").to_stdout
        .and not_to_output.to_stderr
        .and be_a_success
    end
  end
end
