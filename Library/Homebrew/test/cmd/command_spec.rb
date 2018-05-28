describe "brew command", :integration_test do
  it "returns the file for a given command" do
    expect { brew "command", "info" }
      .to output(%r{#{Regexp.escape(HOMEBREW_LIBRARY_PATH)}/cmd/info.rb}).to_stdout
      .and be_a_success
  end
end
