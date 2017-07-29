describe "brew test", :integration_test do
  it "fails when no argument is given" do
    expect { brew "test" }
      .to output(/This command requires a formula argument/).to_stderr
      .and not_to_output.to_stdout
      .and be_a_failure
  end

  it "fails when a Formula is not installed" do
    expect { brew "test", testball }
      .to output(/Testing requires the latest version of testball/).to_stderr
      .and not_to_output.to_stdout
      .and be_a_failure
  end

  it "fails when a Formula has no test" do
    expect { brew "install", testball }.to be_a_success

    expect { brew "test", testball }
      .to output(/testball defines no test/).to_stderr
      .and not_to_output.to_stdout
      .and be_a_failure
  end

  it "tests a given Formula" do
    setup_test_formula "testball", <<-EOS.undent
      head "https://github.com/example/testball2.git"

      devel do
        url "file://#{TEST_FIXTURE_DIR}/tarballs/testball-0.1.tbz"
        sha256 "#{TESTBALL_SHA256}"
      end

      keg_only "just because"

      test do
      end
    EOS

    expect { brew "install", "testball" }.to be_a_success

    expect { brew "test", "--HEAD", "testball" }
      .to output(/Testing testball/).to_stdout
      .and not_to_output.to_stderr
      .and be_a_success

    expect { brew "test", "--devel", "testball" }
      .to output(/Testing testball/).to_stdout
      .and not_to_output.to_stderr
      .and be_a_success
  end
end
