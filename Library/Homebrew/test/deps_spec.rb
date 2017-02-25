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
    expect { brew "deps", "foo" }
      .to be_a_success
      .and not_to_output.to_stdout
      .and not_to_output.to_stderr
  end

  it "outputs a dependency for a Formula that has one dependency" do
    expect { brew "deps", "bar" }
      .to be_a_success
      .and output("foo\n").to_stdout
      .and not_to_output.to_stderr
  end

  it "outputs all of a Formula's dependencies and their dependencies on separate lines" do
    expect { brew "deps", "baz" }
      .to be_a_success
      .and output("bar\nfoo\n").to_stdout
      .and not_to_output.to_stderr
  end
end
