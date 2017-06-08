describe "brew services", :integration_test, :needs_macos, :needs_network do
  it "allows controlling services" do
    setup_remote_tap "homebrew/services"

    expect { brew "services", "list" }
      .to output("Warning: No services available to control with `brew services`\n").to_stderr
      .and not_to_output.to_stdout
      .and be_a_success
  end
end
