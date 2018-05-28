describe "brew migrate", :integration_test do
  before do
    setup_test_formula "testball1"
    setup_test_formula "testball2"
  end

  it "migrates a renamed Formula" do
    install_and_rename_coretap_formula "testball1", "testball2"

    expect { brew "migrate", "testball1" }
      .to output(/Processing testball1 formula rename to testball2/).to_stdout
      .and not_to_output.to_stderr
      .and be_a_success
  end
end
