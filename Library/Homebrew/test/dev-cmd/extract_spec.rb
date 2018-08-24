describe "brew extract", :integration_test do
  it "retrieves the most recent formula version without version argument" do
    path = Tap::TAP_DIRECTORY/"homebrew/homebrew-foo"
    (path/"Formula").mkpath
    target = Tap.from_path(path)
    core_tap = CoreTap.new
    core_tap.path.cd do
      system "git", "init"
      formula_file = setup_test_formula "testball"
      system "git", "add", "--all"
      system "git", "commit", "-m", "testball 0.1"
      contents = File.read(formula_file)
      contents.gsub!("testball-0.1", "testball-0.2")
      File.write(formula_file, contents)
      system "git", "add", "--all"
      system "git", "commit", "-m", "testball 0.2"
    end
    expect { brew "extract", "testball", target.name }
      .to be_a_success

    expect(path/"Formula/testball@0.2.rb").to exist

    expect(Formulary.factory(path/"Formula/testball@0.2.rb").version).to be == "0.2"
  end

  it "does not overwrite existing files, except when running with --force" do
    path = Tap::TAP_DIRECTORY/"homebrew/homebrew-foo"
    (path/"Formula").mkpath
    target = Tap.from_path(path)
    core_tap = CoreTap.new
    core_tap.path.cd do
      system "git", "init"
      formula_file = setup_test_formula "testball"
      system "git", "add", "--all"
      system "git", "commit", "-m", "testball 0.1"
      contents = File.read(formula_file)
      contents.gsub!("testball-0.1", "testball-0.2")
      File.write(formula_file, contents)
      system "git", "add", "--all"
      system "git", "commit", "-m", "testball 0.2"
    end
    expect { brew "extract", "testball", target.name }
      .to be_a_success

    expect(path/"Formula/testball@0.2.rb").to exist

    expect { brew "extract", "testball", target.name }
      .to be_a_failure

    expect { brew "extract", "testball", target.name, "--force" }
      .to be_a_success

    expect { brew "extract", "testball", target.name, "--version=0.1" }
      .to be_a_success

    expect(path/"Formula/testball@0.2.rb").to exist

    expect { brew "extract", "testball", "--version=0.1", target.name }
      .to be_a_failure

    expect { brew "extract", "testball", target.name, "--version=0.1", "--force" }
      .to be_a_success
  end

  it "retrieves the specified formula version when given argument" do
    path = Tap::TAP_DIRECTORY/"homebrew/homebrew-foo"
    (path/"Formula").mkpath
    target = Tap.from_path(path)
    core_tap = CoreTap.new
    core_tap.path.cd do
      system "git", "init"
      formula_file = setup_test_formula "testball"
      system "git", "add", "--all"
      system "git", "commit", "-m", "testball 0.1"
      contents = File.read(formula_file)
      contents.gsub!("testball-0.1", "testball-0.2")
      File.write(formula_file, contents)
      system "git", "add", "--all"
      system "git", "commit", "-m", "testball 0.2"
    end
    expect { brew "extract", "testball", target.name, "--version=0.1" }
      .to be_a_success

    expect { brew "extract", "testball", target.name, "--version=0.1", "--force" }
      .to be_a_success

    expect(Formulary.factory(path/"Formula/testball@0.1.rb").version).to be == "0.1"
  end

  it "retrieves most recent deleted formula when no argument is given" do
    path = Tap::TAP_DIRECTORY/"homebrew/homebrew-foo"
    (path/"Formula").mkpath
    target = Tap.from_path(path)
    core_tap = CoreTap.new
    core_tap.path.cd do
      system "git", "init"
      formula_file = setup_test_formula "testball"
      system "git", "add", "--all"
      system "git", "commit", "-m", "testball 0.1"
      contents = File.read(formula_file)
      contents.gsub!("testball-0.1", "testball-0.2")
      File.write(formula_file, contents)
      system "git", "add", "--all"
      system "git", "commit", "-m", "testball 0.2"
      File.delete(formula_file)
      system "git", "add", "--all"
      system "git", "commit", "-m", "Remove testball"
    end

    expect { brew "extract", "testball", target.name }
      .to be_a_success

    expect(path/"Formula/testball@0.2.rb").to exist

    expect(Formulary.factory(path/"Formula/testball@0.2.rb").version).to be == "0.2"
  end

  it "retrieves old version of deleted formula when argument is given" do
    path = Tap::TAP_DIRECTORY/"homebrew/homebrew-foo"
    (path/"Formula").mkpath
    target = Tap.from_path(path)
    core_tap = CoreTap.new
    core_tap.path.cd do
      system "git", "init"
      formula_file = setup_test_formula "testball"
      system "git", "add", "--all"
      system "git", "commit", "-m", "testball 0.1"
      contents = File.read(formula_file)
      contents.gsub!("testball-0.1", "testball-0.2")
      File.write(formula_file, contents)
      system "git", "add", "--all"
      system "git", "commit", "-m", "testball 0.2"
      File.delete(formula_file)
      system "git", "add", "--all"
      system "git", "commit", "-m", "Remove testball"
    end

    expect { brew "extract", "testball", target.name, "--version=0.1" }
      .to be_a_success

    expect(path/"Formula/testball@0.1.rb").to exist

    expect(Formulary.factory(path/"Formula/testball@0.1.rb").version).to be == "0.1"
  end

  it "retrieves old formulae that use outdated/missing blocks" do
    path = Tap::TAP_DIRECTORY/"homebrew/homebrew-foo"
    (path/"Formula").mkpath
    target = Tap.from_path(path)
    core_tap = CoreTap.new
    core_tap.path.cd do
      system "git", "init"
      contents = <<~EOF
        require 'brewkit'
        class Testball < Formula
          @url="file://#{TEST_FIXTURE_DIR}/tarballs/testball-0.1.tbz"
          @md5='80a8aa0c5a8310392abf3b69f0319204'

          def install
            prefix.install "bin"
            prefix.install "libexec"
            Dir.chdir "doc"
          end
        end
      EOF
      formula_file = core_tap.path/"Formula/testball.rb"
      File.write(formula_file, contents)
      system "git", "add", "--all"
      system "git", "commit", "-m", "testball 0.1"
      contents = File.read(formula_file)
      contents.gsub!("testball-0.1", "testball-0.2")
      File.write(formula_file, contents)
      system "git", "add", "--all"
      system "git", "commit", "-m", "testball 0.2"
      File.delete(formula_file)
      system "git", "add", "--all"
      system "git", "commit", "-m", "Remove testball"
    end

    expect { brew "extract", "testball", target.name, "--version=0.1" }
      .to be_a_success

    expect(path/"Formula/testball@0.1.rb").to exist
  end

  it "fails when formula does not exist" do
    path = Tap::TAP_DIRECTORY/"homebrew/homebrew-foo"
    (path/"Formula").mkpath
    target = Tap.from_path(path)
    core_tap = CoreTap.new
    core_tap.path.cd do
      system "git", "init"
      formula_file = setup_test_formula "testball"
      system "git", "add", "--all"
      system "git", "commit", "-m", "testball 0.1"
      contents = File.read(formula_file)
      contents.gsub!("testball-0.1", "testball-0.2")
      File.write(formula_file, contents)
      system "git", "add", "--all"
      system "git", "commit", "-m", "testball 0.2"
      File.delete(formula_file)
      system "git", "add", "--all"
      system "git", "commit", "-m", "Remove testball"
    end
    expect { brew "extract", "foo", target.name }
      .to be_a_failure
    expect(Dir.entries(path/"Formula").size).to be == 2
  end

  it "fails when formula does not have the specified version" do
    path = Tap::TAP_DIRECTORY/"homebrew/homebrew-foo"
    (path/"Formula").mkpath
    target = Tap.from_path(path)
    core_tap = CoreTap.new
    core_tap.path.cd do
      system "git", "init"
      formula_file = setup_test_formula "testball"
      system "git", "add", "--all"
      system "git", "commit", "-m", "testball 0.1"
      contents = File.read(formula_file)
      contents.gsub!("testball-0.1", "testball-0.2")
      File.write(formula_file, contents)
      system "git", "add", "--all"
      system "git", "commit", "-m", "testball 0.2"
      File.delete(formula_file)
      system "git", "add", "--all"
      system "git", "commit", "-m", "Remove testball"
    end

    expect { brew "extract", "testball", target.name, "--version=0.3" }
      .to be_a_failure

    expect(path/"Formula/testball@0.3.rb").not_to exist
  end
end
