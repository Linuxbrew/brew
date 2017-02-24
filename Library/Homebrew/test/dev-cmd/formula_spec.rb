describe "brew formula", :integration_test do
  it "prints a given Formula's path" do
    formula_file = setup_test_formula "testball"

    expect { brew "formula", "testball" }
      .to output("#{formula_file}\n").to_stdout
      .and not_to_output.to_stderr
      .and be_a_success
  end
end
