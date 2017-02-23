describe "brew commands", :integration_test do
  it "prints a list of all available commands" do
    expect { brew "commands" }
      .to output(/Built-in commands/).to_stdout
      .and be_a_success
  end
end
