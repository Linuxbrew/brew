describe "brew --repository", :integration_test do
  it "prints the path of the Homebrew repository" do
    expect { brew "--repository" }
      .to output("#{HOMEBREW_REPOSITORY}\n").to_stdout
      .and not_to_output.to_stderr
      .and be_a_success
  end

  it "prints the path of a given Tap" do
    expect { brew "--repository", "foo/bar" }
      .to output("#{HOMEBREW_LIBRARY}/Taps/foo/homebrew-bar\n").to_stdout
      .and not_to_output.to_stderr
      .and be_a_success
  end
end
