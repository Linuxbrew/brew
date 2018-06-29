describe "brew linkage", :integration_test do
  before do
    setup_test_formula "testball"
    (HOMEBREW_CELLAR/"testball/0.0.1/foo").mkpath
  end

  it "works when no arguments are provided" do
    expect { brew "linkage" }
      .to be_a_success
      .and not_to_output.to_stdout
      .and not_to_output.to_stderr
  end

  it "works when one argument is provided" do
    expect { brew "linkage", "testball" }
      .to be_a_success
      .and not_to_output.to_stderr
  end
end
