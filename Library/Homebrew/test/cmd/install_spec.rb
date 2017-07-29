describe "brew install", :integration_test do
  it "installs Formulae" do
    setup_test_formula "testball1"

    expect { brew "install", "testball1", "--head" }
      .to output(/Specify `\-\-HEAD`/).to_stderr
      .and not_to_output.to_stdout
      .and be_a_failure

    expect { brew "install", "testball1", "--HEAD" }
      .to output(/No head is defined/).to_stderr
      .and not_to_output.to_stdout
      .and be_a_failure

    expect { brew "install", "testball1", "--devel" }
      .to output(/No devel block/).to_stderr
      .and not_to_output.to_stdout
      .and be_a_failure

    expect { brew "install", "testball1" }
      .to output(%r{#{HOMEBREW_CELLAR}/testball1/0\.1}).to_stdout
      .and not_to_output.to_stderr
      .and be_a_success

    expect { brew "install", "testball1" }
      .to output(/testball1\ 0\.1 is already installed/).to_stderr
      .and not_to_output.to_stdout
      .and be_a_success

    expect { brew "install", "macruby" }
      .to output(/MacRuby is not packaged/).to_stderr
      .and not_to_output.to_stdout
      .and be_a_failure

    expect { brew "install", "formula" }
      .to output(/No available formula/).to_stderr
      .and output(/Searching for similarly named formulae/).to_stdout
      .and be_a_failure

    expect { brew "install", "testball" }
      .to output(/This similarly named formula was found/).to_stdout
      .and output(/No available formula/).to_stderr
      .and be_a_failure

    setup_test_formula "testball2"
    expect { brew "install", "testball" }
      .to output(/These similarly named formulae were found/).to_stdout
      .and output(/No available formula/).to_stderr
      .and be_a_failure

    install_and_rename_coretap_formula "testball1", "testball2"
    expect { brew "install", "testball2" }
      .to output(/testball1 already installed, it's just not migrated/).to_stderr
      .and not_to_output.to_stdout
      .and be_a_success
  end

  specify "install failures" do
    path = setup_test_formula "testball1", <<-EOS.undent
      version "1.0"
    EOS

    expect { brew "install", "testball1" }
      .to output(%r{#{HOMEBREW_CELLAR}/testball1/1\.0}).to_stdout
      .and not_to_output.to_stderr
      .and be_a_success

    FileUtils.rm path
    setup_test_formula "testball1", <<-EOS.undent
      version "2.0"

      devel do
        url "#{Formulary.factory("testball1").stable.url}"
        sha256 "#{TESTBALL_SHA256}"
        version "3.0"
      end
    EOS

    expect { brew "install", "testball1" }
      .to output(/`brew upgrade testball1`/).to_stderr
      .and not_to_output.to_stdout
      .and be_a_failure

    expect { brew "unlink", "testball1" }
      .to output(%r{#{HOMEBREW_CELLAR}/testball1/1\.0}).to_stdout
      .and not_to_output.to_stderr
      .and be_a_success

    expect { brew "install", "testball1", "--devel" }
      .to output(%r{#{HOMEBREW_CELLAR}/testball1/3\.0}).to_stdout
      .and not_to_output.to_stderr
      .and be_a_success

    expect { brew "unlink", "testball1" }
      .to output(%r{#{HOMEBREW_CELLAR}/testball1/3\.0}).to_stdout
      .and not_to_output.to_stderr
      .and be_a_success

    expect { brew "install", "testball1" }
      .to output(%r{#{HOMEBREW_CELLAR}/testball1/2\.0}).to_stdout
      .and not_to_output.to_stderr
      .and be_a_success

    expect { brew "switch", "testball1", "3.0" }.to be_a_success

    expect { brew "install", "testball1" }
      .to output(/2.0 is already installed/).to_stderr
      .and not_to_output.to_stdout
      .and be_a_success

    expect { brew "unlink", "testball1" }
      .to output(%r{#{HOMEBREW_CELLAR}/testball1/3\.0}).to_stdout
      .and not_to_output.to_stderr
      .and be_a_success

    expect { brew "install", "testball1" }
      .to output(/just not linked/).to_stderr
      .and not_to_output.to_stdout
      .and be_a_success
  end

  it "can install keg-only Formulae" do
    path_keg_only = setup_test_formula "testball1", <<-EOS.undent
      version "1.0"

      keg_only "test reason"
    EOS

    expect { brew "install", "testball1" }
      .to output(%r{#{HOMEBREW_CELLAR}/testball1/1\.0}).to_stdout
      .and not_to_output.to_stderr
      .and be_a_success

    FileUtils.rm path_keg_only
    setup_test_formula "testball1", <<-EOS.undent
      version "2.0"

      keg_only "test reason"
    EOS

    expect { brew "install", "testball1" }
      .to output(/testball1 1.0 is already installed/).to_stderr
      .and not_to_output.to_stdout
      .and be_a_success

    expect { brew "install", "testball1", "--force" }
      .to output(%r{#{HOMEBREW_CELLAR}/testball1/2\.0}).to_stdout
      .and not_to_output.to_stderr
      .and be_a_success
  end

  it "can install HEAD Formulae" do
    repo_path = HOMEBREW_CACHE.join("repo")
    repo_path.join("bin").mkpath

    repo_path.cd do
      system "git", "init"
      system "git", "remote", "add", "origin", "https://github.com/Homebrew/homebrew-foo"
      FileUtils.touch "bin/something.bin"
      FileUtils.touch "README"
      system "git", "add", "--all"
      system "git", "commit", "-m", "Initial repo commit"
    end

    setup_test_formula "testball1", <<-EOS.undent
      version "1.0"

      head "file://#{repo_path}", :using => :git

      def install
        prefix.install Dir["*"]
      end
    EOS

    # Ignore dependencies, because we'll try to resolve requirements in build.rb
    # and there will be the git requirement, but we cannot instantiate git
    # formula since we only have testball1 formula.
    expect { brew "install", "testball1", "--HEAD", "--ignore-dependencies" }
      .to output(%r{#{HOMEBREW_CELLAR}/testball1/HEAD\-d5eb689}).to_stdout
      .and output(/Cloning into/).to_stderr
      .and be_a_success

    expect { brew "install", "testball1", "--HEAD", "--ignore-dependencies" }
      .to output(/testball1 HEAD\-d5eb689 is already installed/).to_stderr
      .and not_to_output.to_stdout
      .and be_a_success

    expect { brew "unlink", "testball1" }
      .to output(%r{#{HOMEBREW_CELLAR}/testball1/HEAD\-d5eb689}).to_stdout
      .and not_to_output.to_stderr
      .and be_a_success

    expect { brew "install", "testball1" }
      .to output(%r{#{HOMEBREW_CELLAR}/testball1/1\.0}).to_stdout
      .and not_to_output.to_stderr
      .and be_a_success
  end

  it "ignores invalid options" do
    setup_test_formula "testball1"
    expect { brew "install", "testball1", "--with-fo" }
      .to output(/testball1: this formula has no \-\-with\-fo option so it will be ignored!/).to_stderr
      .and output(/Downloading file/).to_stdout
      .and be_a_success
  end

  it "succeeds when a non-fatal requirement isn't satisfied" do
    setup_test_formula "testball1", <<-EOS.undent
      class NonFatalRequirement < Requirement
        satisfy { false }
      end

      depends_on NonFatalRequirement
    EOS

    expect { brew "install", "testball1" }
      .to output(/NonFatalRequirement unsatisfied!/).to_stderr
      .and output(/built in/).to_stdout
      .and be_a_success
  end

  it "fails when a fatal requirement isn't satisfied" do
    setup_test_formula "testball1", <<-EOS.undent
      class FatalRequirement < Requirement
        fatal true
        satisfy { false }
      end

      depends_on FatalRequirement
    EOS

    expect { brew "install", "testball1" }
      .to output(/FatalRequirement unsatisfied!/).to_stderr
      .and not_to_output.to_stdout
      .and be_a_failure
  end
end
