describe "brew missing", :integration_test do
  before do
    setup_test_formula "foo"
    setup_test_formula "bar"
  end

  def make_prefix(name)
    (HOMEBREW_CELLAR/name/"1.0").mkpath
  end

  it "prints missing dependencies" do
    make_prefix "bar"

    expect { brew "missing" }
      .to output("foo\n").to_stdout
      .and not_to_output.to_stderr
      .and be_a_failure
  end

  it "prints nothing if all dependencies are installed" do
    make_prefix "foo"
    make_prefix "bar"

    expect { brew "missing" }
      .to be_a_success
      .and not_to_output.to_stdout
      .and not_to_output.to_stderr
  end

  describe "--hide=" do
    it "pretends that the specified Formulae are not installed" do
      make_prefix "foo"
      make_prefix "bar"

      expect { brew "missing", "--hide=foo" }
        .to output("bar: foo\n").to_stdout
        .and not_to_output.to_stderr
        .and be_a_failure
    end
  end
end
