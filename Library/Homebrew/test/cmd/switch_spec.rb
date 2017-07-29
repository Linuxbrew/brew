describe "brew switch", :integration_test do
  it "allows switching between Formula versions" do
    expect { brew "switch" }
      .to output(/Usage: brew switch <name> <version>/).to_stderr
      .and not_to_output.to_stdout
      .and be_a_failure

    expect { brew "switch", "testball", "0.1" }
      .to output(/testball not found/).to_stderr
      .and not_to_output.to_stdout
      .and be_a_failure

    setup_test_formula "testball", <<-EOS.undent
      keg_only "just because"
    EOS

    expect { brew "install", "testball" }.to be_a_success

    testball_rack = HOMEBREW_CELLAR/"testball"
    FileUtils.cp_r testball_rack/"0.1", testball_rack/"0.2"

    expect { brew "switch", "testball", "0.2" }
      .to output(/link created/).to_stdout
      .and not_to_output.to_stderr
      .and be_a_success

    expect { brew "switch", "testball", "0.3" }
      .to output("Versions available: 0.1, 0.2\n").to_stdout
      .and output(/testball does not have a version "0.3"/).to_stderr
      .and be_a_failure
  end
end
