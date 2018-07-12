describe "brew test", :integration_test do
  it "tests a given Formula" do
    setup_test_formula "testball", <<~RUBY
      head "https://github.com/example/testball2.git"

      devel do
        url "file://#{TEST_FIXTURE_DIR}/tarballs/testball-0.1.tbz"
        sha256 "#{TESTBALL_SHA256}"
      end

      keg_only "just because"

      test do
      end
    RUBY

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
