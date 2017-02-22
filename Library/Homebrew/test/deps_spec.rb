describe Homebrew do
  describe "#deps" do
    setup_test_formula "foo"
    setup_test_formula "bar"
    setup_test_formula "baz", <<-EOS.undent
      url "https://example.com/baz-1.0"
      depends_on "bar"
    EOS

    expect(cmd("deps", "foo")).to eq("")
    expect(cmd("deps", "bar")).to eq("foo")
    expect(cmd("deps", "baz")).to eq("bar\nfoo")
  end
end
