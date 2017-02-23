describe "brew readall", :integration_test do
  it "imports all Formulae for a given Tap" do
    formula_file = setup_test_formula "testball"

    alias_file = CoreTap.new.alias_dir/"foobar"
    alias_file.parent.mkpath

    FileUtils.ln_s formula_file, alias_file

    expect { brew "readall", "--aliases", "--syntax" }
      .to be_a_success
      .and not_to_output.to_stdout
      .and not_to_output.to_stderr

    expect { brew "readall", "homebrew/core" }
      .to be_a_success
      .and not_to_output.to_stdout
      .and not_to_output.to_stderr
  end
end
