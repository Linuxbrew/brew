describe "brew pull", :integration_test do
  it "fails when no argument is given" do
    expect { brew "pull" }
      .to output(/This command requires at least one argument/).to_stderr
      .and not_to_output.to_stdout
      .and be_a_failure
  end

  it "fetches a patch from a GitHub commit or pull request and applies it", :needs_network do
    CoreTap.instance.path.cd do
      system "git", "init"
      system "git", "checkout", "-b", "new-branch"
    end

    expect { brew "pull", "https://jenkins.brew.sh/job/Homebrew\%20Testing/1028/" }
      .to output(/Testing URLs require `\-\-bottle`!/).to_stderr
      .and not_to_output.to_stdout
      .and be_a_failure

    expect { brew "pull", "1" }
      .to output(/Fetching patch/).to_stdout
      .and output(/Current branch is new\-branch/).to_stderr
      .and be_a_failure

    expect { brew "pull", "--bump", "8" }
      .to output(/Fetching patch/).to_stdout
      .and output(/No changed formulae found to bump/).to_stderr
      .and be_a_failure

    expect { brew "pull", "--bump", "https://api.github.com/repos/Homebrew/homebrew-core/pulls/122" }
      .to output(/Fetching patch/).to_stdout
      .and output(/Can only bump one changed formula/).to_stderr
      .and be_a_failure

    expect { brew "pull", "https://github.com/Homebrew/brew/pull/1249" }
      .to output(/Fetching patch/).to_stdout
      .and output(/Patch failed to apply/).to_stderr
      .and be_a_failure
  end

  describe "--rebase" do
    it "fails" do
      expect { brew "pull", "--rebase" }
        .to output(/You meant `git pull --rebase`./).to_stderr
        .and not_to_output.to_stdout
        .and be_a_failure
    end
  end

  it "fails when given 0" do
    expect { brew "pull", "0" }
      .to output(/Not a GitHub pull request or commit/).to_stderr
      .and not_to_output.to_stdout
      .and be_a_failure
  end
end
