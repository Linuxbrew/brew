describe "brew tap", :integration_test do
  it "taps a given Tap" do
    path = Tap::TAP_DIRECTORY/"homebrew/homebrew-foo"
    path.mkpath
    path.cd do
      system "git", "init"
      system "git", "remote", "add", "origin", "https://github.com/Homebrew/homebrew-foo"
      FileUtils.touch "readme"
      system "git", "add", "--all"
      system "git", "commit", "-m", "init"
    end

    expect { brew "tap" }
      .to output(%r{homebrew/foo}).to_stdout
      .and not_to_output.to_stderr
      .and be_a_success

    expect { brew "tap", "--list-official" }
      .to output(%r{homebrew/science}).to_stdout
      .and not_to_output.to_stderr
      .and be_a_success

    expect { brew "tap-info" }
      .to output(/2 taps/).to_stdout
      .and not_to_output.to_stderr
      .and be_a_success

    expect { brew "tap-info", "homebrew/foo" }
      .to output(%r{https://github\.com/Homebrew/homebrew-foo}).to_stdout
      .and not_to_output.to_stderr
      .and be_a_success

    expect { brew "tap-info", "--json=v1", "--installed" }
      .to output(%r{https://github\.com/Homebrew/homebrew-foo}).to_stdout
      .and not_to_output.to_stderr
      .and be_a_success

    expect { brew "tap-pin", "homebrew/foo" }
      .to output(%r{Pinned homebrew/foo}).to_stdout
      .and not_to_output.to_stderr
      .and be_a_success

    expect { brew "tap", "--list-pinned" }
      .to output(%r{homebrew/foo}).to_stdout
      .and not_to_output.to_stderr
      .and be_a_success

    expect { brew "tap-unpin", "homebrew/foo" }
      .to output(%r{Unpinned homebrew/foo}).to_stdout
      .and not_to_output.to_stderr
      .and be_a_success

    expect { brew "tap", "homebrew/bar", path/".git" }
      .to output(/Tapped/).to_stdout
      .and output(/Cloning/).to_stderr
      .and be_a_success

    expect { brew "untap", "homebrew/bar" }
      .to output(/Untapped/).to_stdout
      .and not_to_output.to_stderr
      .and be_a_success

    expect { brew "tap", "homebrew/bar", path/".git", "-q", "--full" }
      .to be_a_success
      .and not_to_output.to_stdout
      .and not_to_output.to_stderr

    expect { brew "untap", "homebrew/bar" }
      .to output(/Untapped/).to_stdout
      .and not_to_output.to_stderr
      .and be_a_success
  end
end
