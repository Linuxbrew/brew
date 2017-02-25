describe "brew tap-new", :integration_test do
  it "initializes a new Tap with a ReadMe file" do
    expect { brew "tap-new", "homebrew/foo", "--verbose" }
      .to be_a_success
      .and not_to_output.to_stdout
      .and not_to_output.to_stderr

    expect(HOMEBREW_LIBRARY/"Taps/homebrew/homebrew-foo/README.md").to exist
  end
end
