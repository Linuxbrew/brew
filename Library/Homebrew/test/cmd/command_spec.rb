describe "brew command", :integration_test do
  it "returns the file for a given command" do
    expect { brew "command", "info" }
      .to output(%r{#{Regexp.escape(HOMEBREW_LIBRARY_PATH)}/cmd/info.rb}).to_stdout
      .and be_a_success
  end

  it "fails when the given command is unknown" do
    expect { brew "command", "does-not-exist" }
      .to output(/Unknown command/).to_stderr
      .and be_a_failure
  end
end
