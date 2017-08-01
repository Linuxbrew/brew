describe "brew log", :integration_test do
  it "shows the Git log for the Homebrew repository when no argument is given" do
    HOMEBREW_REPOSITORY.cd do
      system "git", "init"
      system "git", "commit", "--allow-empty", "-m", "This is a test commit"
    end

    expect { brew "log" }
      .to output(/This is a test commit/).to_stdout
      .and not_to_output.to_stderr
      .and be_a_success
  end

  it "shows the Git log for a given Formula" do
    setup_test_formula "testball"

    core_tap = CoreTap.new
    core_tap.path.cd do
      system "git", "init"
      system "git", "add", "--all"
      system "git", "commit", "-m", "This is a test commit for Testball"
    end

    core_tap_url = "file://#{core_tap.path}"
    shallow_tap = Tap.fetch("homebrew", "shallow")

    system "git", "clone", "--depth=1", core_tap_url, shallow_tap.path

    expect { brew "log", "#{shallow_tap}/testball" }
      .to output(/This is a test commit for Testball/).to_stdout
      .and output(%r{Warning: homebrew/shallow is a shallow clone}).to_stderr
      .and be_a_success

    expect(shallow_tap.path/".git/shallow").to exist, "A shallow clone should have been created."
  end
end
