describe "brew unlink", :integration_test do
  it "unlinks a Formula" do
    setup_test_formula "testball"

    expect { brew "install", "testball" }.to be_a_success

    expect { brew "unlink", "--dry-run", "testball" }
      .to output(/Would remove/).to_stdout
      .and not_to_output.to_stderr
      .and be_a_success
  end
end
