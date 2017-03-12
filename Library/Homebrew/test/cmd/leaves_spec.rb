describe "brew leaves", :integration_test do
  it "prints all Formulae that are not dependencies of other Formulae" do
    setup_test_formula "foo"
    setup_test_formula "bar"

    expect { brew "leaves" }
      .to be_a_success
      .and not_to_output.to_stdout
      .and not_to_output.to_stderr

    (HOMEBREW_CELLAR/"foo/0.1/somedir").mkpath
    expect { brew "leaves" }
      .to output("foo\n").to_stdout
      .and not_to_output.to_stderr
      .and be_a_success

    (HOMEBREW_CELLAR/"bar/0.1/somedir").mkpath
    expect { brew "leaves" }
      .to output("bar\n").to_stdout
      .and not_to_output.to_stderr
      .and be_a_success
  end
end
