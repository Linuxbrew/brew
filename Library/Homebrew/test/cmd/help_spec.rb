describe "brew", :integration_test do
  it "prints help when no argument is given" do
    expect { brew }
      .to output(/Example usage:\n/).to_stderr
      .and be_a_failure
  end

  describe "help" do
    it "prints help" do
      expect { brew "help" }
        .to output(/Example usage:\n/).to_stdout
        .and be_a_success
    end

    it "prints help for a documented Ruby command" do
      expect { brew "help", "cat" }
        .to output(/^brew cat/).to_stdout
        .and be_a_success
    end

    it "prints help for a documented shell command" do
      expect { brew "help", "update" }
        .to output(/^brew update/).to_stdout
        .and be_a_success
    end

    it "prints help for a documented Ruby developer command" do
      expect { brew "help", "update-test" }
        .to output(/^brew update-test/).to_stdout
        .and be_a_success
    end

    it "fails when given an unknown command" do
      expect { brew "help", "command-that-does-not-exist" }
        .to output(/Unknown command: command-that-does-not-exist/).to_stderr
        .and be_a_failure
    end
  end

  describe "cat" do
    it "prints help when no argument is given" do
      expect { brew "cat" }
        .to output(/^brew cat/).to_stderr
        .and be_a_failure
    end
  end
end
