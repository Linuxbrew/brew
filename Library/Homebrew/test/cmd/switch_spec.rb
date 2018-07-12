describe "brew switch", :integration_test do
  it "allows switching between Formula versions" do
    setup_test_formula "testball", <<~RUBY
      keg_only "just because"
    RUBY

    expect { brew "install", "testball" }.to be_a_success

    testball_rack = HOMEBREW_CELLAR/"testball"
    FileUtils.cp_r testball_rack/"0.1", testball_rack/"0.2"

    expect { brew "switch", "testball", "0.2" }
      .to output(/link created/).to_stdout
      .and not_to_output.to_stderr
      .and be_a_success
  end
end
