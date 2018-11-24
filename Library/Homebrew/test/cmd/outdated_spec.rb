describe "brew outdated", :integration_test do
  context "quiet output" do
    it "prints outdated Formulae" do
      setup_test_formula "testball"
      (HOMEBREW_CELLAR/"testball/0.0.1/foo").mkpath

      setup_test_formula "foo"
      (HOMEBREW_CELLAR/"foo/0.0.1/foo").mkpath

      expect { brew "outdated" }
        .to output("foo\ntestball\n").to_stdout
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

  context "pinned formula, verbose output" do
    it "prints out the pinned version" do
      setup_test_formula "testball"
      (HOMEBREW_CELLAR/"testball/0.0.1/foo").mkpath

      expect { brew "pin", "testball" }.to be_a_success

      expect { brew "outdated", "--verbose" }
        .to output("testball (0.0.1) < 0.1 [pinned at 0.0.1]\n").to_stdout
        .and not_to_output.to_stderr
        .and be_a_success
    end
  end

  context "json output" do
    it "includes pinned version in the json output" do
      setup_test_formula "testball"
      (HOMEBREW_CELLAR/"testball/0.0.1/foo").mkpath

      expect { brew "pin", "testball" }.to be_a_success

      expected_json = [
        {
          name:               "testball",
          installed_versions: ["0.0.1"],
          current_version:    "0.1",
          pinned:             true,
          pinned_version:     "0.0.1",
        },
      ].to_json

      expect { brew "outdated", "--json=v1" }
        .to output(expected_json + "\n").to_stdout
        .and not_to_output.to_stderr
        .and be_a_success
    end

    it "has no pinned version when the formula isn't pinned" do
      setup_test_formula "testball"
      (HOMEBREW_CELLAR/"testball/0.0.1/foo").mkpath

      expected_json = [
        {
          name:               "testball",
          installed_versions: ["0.0.1"],
          current_version:    "0.1",
          pinned:             false,
          pinned_version:     nil,
        },
      ].to_json

      expect { brew "outdated", "--json=v1" }
        .to output(expected_json + "\n").to_stdout
        .and not_to_output.to_stderr
        .and be_a_success
    end
  end
end
