describe "brew uses", :integration_test do
  it "prints the Formulae a given Formula is used by" do
    setup_test_formula "foo"
    setup_test_formula "bar"
    setup_test_formula "baz", <<~RUBY
      url "https://example.com/baz-1.0"
      depends_on "bar"
    RUBY

    expect { brew "uses", "baz" }
      .to be_a_success
      .and not_to_output.to_stdout
      .and not_to_output.to_stderr

    expect { brew "uses", "bar" }
      .to output("baz\n").to_stdout
      .and not_to_output.to_stderr
      .and be_a_success

    expect { brew "uses", "--recursive", "foo" }
      .to output(/(bar\nbaz|baz\nbar)/).to_stdout
      .and not_to_output.to_stderr
      .and be_a_success
  end
end
