describe "brew cat", :integration_test do
  it "prints the content of a given Formula" do
    formula_file = setup_test_formula "testball"
    content = formula_file.read

    expect { brew "cat", "testball" }
      .to output(content).to_stdout
      .and not_to_output.to_stderr
      .and be_a_success
  end
end
