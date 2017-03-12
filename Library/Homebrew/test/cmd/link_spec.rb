describe "brew link", :integration_test do
  it "fails when no argument is given" do
    expect { brew "link" }
      .to output(/This command requires a keg argument/).to_stderr
      .and not_to_output.to_stdout
      .and be_a_failure
  end

  it "does not fail if the given Formula is already linked" do
    setup_test_formula "testball1"

    shutup do
      expect { brew "install", "testball1" }.to be_a_success
      expect { brew "link", "testball1" }.to be_a_success
    end
  end

  it "links a given Formula" do
    setup_test_formula "testball1"

    shutup do
      expect { brew "install", "testball1" }.to be_a_success
      expect { brew "unlink", "testball1" }.to be_a_success
    end

    expect { brew "link", "--dry-run", "testball1" }
      .to output(/Would link/).to_stdout
      .and not_to_output.to_stderr
      .and be_a_success

    expect { brew "link", "--dry-run", "--overwrite", "testball1" }
      .to output(/Would remove/).to_stdout
      .and not_to_output.to_stderr
      .and be_a_success

    expect { brew "link", "testball1" }
      .to output(/Linking/).to_stdout
      .and not_to_output.to_stderr
      .and be_a_success
  end

  it "refuses to link keg-only Formulae" do
    setup_test_formula "testball1", <<-EOS.undent
      keg_only "just because"
    EOS

    shutup do
      expect { brew "install", "testball1" }.to be_a_success
    end

    expect { brew "link", "testball1" }
      .to output(/testball1 is keg-only/).to_stderr
      .and output(/Note that doing so can interfere with building software\./).to_stdout
      .and be_a_success
  end
end
