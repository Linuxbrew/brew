describe "brew info", :integration_test do
  it "prints information about a given Formula" do
    setup_test_formula "testball"

    expect { brew "info", "testball" }
      .to output(/testball: stable 0.1/).to_stdout
      .and not_to_output.to_stderr
      .and be_a_success
  end
end
