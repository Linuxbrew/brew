describe "brew deps", :integration_test do
  before(:each) do
    setup_test_formula "foo"
    setup_test_formula "bar"
    setup_test_formula "baz", <<-EOS.undent
      url "https://example.com/baz-1.0"
      depends_on "bar"
    EOS
  end

  it "outputs no dependencies for a Formula that has no dependencies" do
    expect { brew "deps", "foo" }.to output("").to_stdout
      .and not_to_output.to_stderr
      .and be_a_success
  end

  it "outputs a dependency for a Formula that has one dependency" do
    expect { brew "deps", "bar" }.to output("foo\n").to_stdout
      .and not_to_output.to_stderr
      .and be_a_success
  end

  it "outputs dependencies on separate lines for a Formula that has multiple dependencies" do
    expect { brew "deps", "baz" }.to output("bar\nfoo\n").to_stdout
      .and not_to_output.to_stderr
      .and be_a_success
  end
end
