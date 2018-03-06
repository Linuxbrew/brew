describe "brew ruby", :integration_test do
  it "executes ruby code with Homebrew's libraries loaded" do
    expect { brew "ruby", "-e", "exit 0" }
      .to be_a_success
      .and not_to_output.to_stdout
      .and not_to_output.to_stderr

    expect { brew "ruby", "-e", "exit 1" }
      .to be_a_failure
      .and not_to_output.to_stdout
      .and not_to_output.to_stderr
  end
end
