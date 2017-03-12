describe "brew migrate", :integration_test do
  before(:each) do
    setup_test_formula "testball1"
    setup_test_formula "testball2"
  end

  it "fails when no argument is given" do
    expect { brew "migrate" }
      .to output(/Invalid usage/).to_stderr
      .and not_to_output.to_stdout
      .and be_a_failure
  end

  it "fails when a given Formula doesn't exist" do
    expect { brew "migrate", "testball" }
      .to output(/No available formula with the name "testball"/).to_stderr
      .and not_to_output.to_stdout
      .and be_a_failure
  end

  it "fails if a given Formula doesn't replace another one" do
    expect { brew "migrate", "testball1" }
      .to output(/testball1 doesn't replace any formula/).to_stderr
      .and not_to_output.to_stdout
      .and be_a_failure
  end

  it "migrates a renamed Formula" do
    install_and_rename_coretap_formula "testball1", "testball2"

    expect { brew "migrate", "testball1" }
      .to output(/Migrating testball1 to testball2/).to_stdout
      .and not_to_output.to_stderr
      .and be_a_success
  end

  it "fails if a given Formula is not installed" do
    install_and_rename_coretap_formula "testball1", "testball2"
    (HOMEBREW_CELLAR/"testball1").rmtree

    expect { brew "migrate", "testball1" }
      .to output(/Error: No such keg/).to_stderr
      .and not_to_output.to_stdout
      .and be_a_failure
  end
end
