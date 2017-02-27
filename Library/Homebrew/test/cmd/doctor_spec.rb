describe "brew doctor", :integration_test do
  specify "check_integration_test" do
    expect { brew "doctor", "check_integration_test" }
      .to output(/This is an integration test/).to_stderr
  end
end
