describe "brew uses", :integration_test do
  it "prints the Formulae a given Formula is used by" do
    setup_test_formula "foo"
    setup_test_formula "bar"
    setup_test_formula "baz", <<-EOS.undent
      url "https://example.com/baz-1.0"
      depends_on "bar"
    EOS

    # This test would fail when HOMEBREW_VERBOSE_USING_DOTS is set,
    # as is the case on Linuxbrew's Travis. Rather than convolute
    # logic, just force that variable to be on and change the
    # expectation.
    expect { brew "uses", "baz", "HOMEBREW_VERBOSE_USING_DOTS" => "1" }
      .to be_a_success
      .and not_to_output.to_stdout
      .and output(".\n").to_stderr

    expect { brew "uses", "bar", "HOMEBREW_VERBOSE_USING_DOTS" => "1" }
      .to output("baz\n").to_stdout
      .and output(".\n").to_stderr
      .and be_a_success

    expect { brew "uses", "--recursive", "foo", "HOMEBREW_VERBOSE_USING_DOTS" => "1" }
      .to output(/(bar\nbaz|baz\nbar)/).to_stdout
      .and output(".\n").to_stderr
      .and be_a_success
  end
end
