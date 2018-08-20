describe "brew extract", :integration_test do
  it "extracts the most recent formula version without version argument" do
    path = Tap::TAP_DIRECTORY/"homebrew/homebrew-foo"
    (path/"Formula").mkpath
    target = Tap.from_path(path)
    formula_file = setup_test_formula "foo"

    expect { brew "extract", "foo", target.name }
      .to be_a_success

    expect(path/"Formula/foo@1.0.rb").to exist
  end
end
