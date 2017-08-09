describe "brew config", :integration_test do
  it "prints information about the current Homebrew configuration" do
    expect { brew "config" }
      .to output(/HOMEBREW_VERSION: #{Regexp.escape HOMEBREW_VERSION}/).to_stdout
      .and not_to_output.to_stderr
      .and be_a_success
  end
end
