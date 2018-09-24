describe "brew cat", :integration_test do
  it "prints the content of a given Formula" do
    formula_file = setup_test_formula "testball"
    content = formula_file.read

    expect { brew "cat", "testball" }
      .to output(content).to_stdout
      .and not_to_output.to_stderr
      .and be_a_success
  end

  it "fails when given multiple arguments" do
    setup_test_formula "foo"
    setup_test_formula "bar"
    expect { brew "cat", "foo", "bar" }
      .to output(/doesn't support multiple arguments/).to_stderr
      .and not_to_output.to_stdout
      .and be_a_failure
  end
end
