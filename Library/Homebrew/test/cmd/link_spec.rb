describe "brew link", :integration_test do
  it "fails when no argument is given" do
    expect { brew "link" }
      .to output(/This command requires a keg argument/).to_stderr
      .and not_to_output.to_stdout
      .and be_a_failure
  end

  it "does not fail if the given Formula is already linked" do
    setup_test_formula "testball1"

    expect { brew "install", "testball1" }.to be_a_success
    expect { brew "link", "testball1" }.to be_a_success
  end

  it "links a given Formula" do
    setup_test_formula "testball1"

    expect { brew "install", "testball1" }.to be_a_success
    expect { brew "unlink", "testball1" }.to be_a_success

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

    expect { brew "install", "testball1" }.to be_a_success

    expect { brew "link", "testball1", "SHELL" => "/bin/zsh" }
      .to output(/testball1 is keg-only/).to_stderr
      .and output(a_string_matching(/Note that doing so can interfere with building software\./)
        .and(matching("If you need to have this software first in your PATH instead consider running:")
        .and(including("echo 'export PATH=\"#{HOMEBREW_PREFIX}/opt/testball1/bin:$PATH\"' >> ~/.zshrc")))).to_stdout
      .and be_a_success
  end
end
