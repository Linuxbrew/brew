require "testing_env"

class IntegrationCommandTestInstall < IntegrationCommandTestCase
  def test_install
    setup_test_formula "testball1"
    assert_match "Specify `--HEAD`", cmd_fail("install", "testball1", "--head")
    assert_match "No head is defined", cmd_fail("install", "testball1", "--HEAD")
    assert_match "No devel block", cmd_fail("install", "testball1", "--devel")
    assert_match "#{HOMEBREW_CELLAR}/testball1/0.1", cmd("install", "testball1")
    assert_match "testball1-0.1 already installed", cmd("install", "testball1")
    assert_match "MacRuby is not packaged", cmd_fail("install", "macruby")
    assert_match "No available formula", cmd_fail("install", "formula")
    assert_match "This similarly named formula was found",
      cmd_fail("install", "testball")

    setup_test_formula "testball2"
    assert_match "These similarly named formulae were found",
      cmd_fail("install", "testball")

    install_and_rename_coretap_formula "testball1", "testball2"
    assert_match "testball1 already installed, it's just not migrated",
      cmd("install", "testball2")
  end

  def test_install_failures
    path = setup_test_formula "testball1", "version \"1.0\""
    devel_content = <<-EOS.undent
      version "3.0"
      devel do
        url "#{Formulary.factory("testball1").stable.url}"
        sha256 "#{TESTBALL_SHA256}"
        version "2.0"
      end
    EOS

    assert_match "#{HOMEBREW_CELLAR}/testball1/1.0", cmd("install", "testball1")

    FileUtils.rm path
    setup_test_formula "testball1", devel_content

    assert_match "first `brew unlink testball1`", cmd_fail("install", "testball1")
    assert_match "#{HOMEBREW_CELLAR}/testball1/1.0", cmd("unlink", "testball1")
    assert_match "#{HOMEBREW_CELLAR}/testball1/2.0", cmd("install", "testball1", "--devel")
    assert_match "#{HOMEBREW_CELLAR}/testball1/2.0", cmd("unlink", "testball1")
    assert_match "#{HOMEBREW_CELLAR}/testball1/3.0", cmd("install", "testball1")

    cmd("switch", "testball1", "2.0")
    assert_match "already installed, however linked version is",
      cmd("install", "testball1")
    assert_match "#{HOMEBREW_CELLAR}/testball1/2.0", cmd("unlink", "testball1")
    assert_match "just not linked", cmd("install", "testball1")
  end

  def test_install_keg_only_outdated
    path_keg_only = setup_test_formula "testball1", <<-EOS.undent
    version "1.0"
    keg_only "test reason"
    EOS

    assert_match "#{HOMEBREW_CELLAR}/testball1/1.0", cmd("install", "testball1")

    FileUtils.rm path_keg_only
    setup_test_formula "testball1", <<-EOS.undent
      version "2.0"
      keg_only "test reason"
    EOS

    assert_match "keg-only and another version is linked to opt",
      cmd("install", "testball1")

    assert_match "#{HOMEBREW_CELLAR}/testball1/2.0",
      cmd("install", "testball1", "--force")
  end

  def test_install_head_installed
    initial_env = ENV.to_hash
    %w[AUTHOR COMMITTER].each do |role|
      ENV["GIT_#{role}_NAME"] = "brew tests"
      ENV["GIT_#{role}_EMAIL"] = "brew-tests@localhost"
      ENV["GIT_#{role}_DATE"] = "Thu May 21 00:04:11 2009 +0100"
    end

    repo_path = HOMEBREW_CACHE.join("repo")
    repo_path.join("bin").mkpath

    repo_path.cd do
      shutup do
        system "git", "init"
        system "git", "remote", "add", "origin", "https://github.com/Homebrew/homebrew-foo"
        FileUtils.touch "bin/something.bin"
        FileUtils.touch "README"
        system "git", "add", "--all"
        system "git", "commit", "-m", "Initial repo commit"
      end
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
    assert_match "#{HOMEBREW_CELLAR}/testball1/HEAD-2ccdf4f", cmd("install", "testball1", "--HEAD", "--ignore-dependencies")
    assert_match "testball1-HEAD-2ccdf4f already installed",
      cmd("install", "testball1", "--HEAD", "--ignore-dependencies")
    assert_match "#{HOMEBREW_CELLAR}/testball1/HEAD-2ccdf4f", cmd("unlink", "testball1")
    assert_match "#{HOMEBREW_CELLAR}/testball1/1.0", cmd("install", "testball1")

  ensure
    ENV.replace(initial_env)
    repo_path.rmtree
  end

  def test_install_with_invalid_option
    setup_test_formula "testball1"
    assert_match "testball1: this formula has no --with-fo option so it will be ignored!",
      cmd("install", "testball1", "--with-fo")
  end

  def test_install_with_nonfatal_requirement
    setup_test_formula "testball1", <<-EOS.undent
      class NonFatalRequirement < Requirement
        satisfy { false }
      end
      depends_on NonFatalRequirement
    EOS
    message = "NonFatalRequirement unsatisfied!"
    assert_equal 1, cmd("install", "testball1").scan(message).size
  end

  def test_install_with_fatal_requirement
    setup_test_formula "testball1", <<-EOS.undent
      class FatalRequirement < Requirement
        fatal true
        satisfy { false }
      end
      depends_on FatalRequirement
    EOS
    message = "FatalRequirement unsatisfied!"
    assert_equal 1, cmd_fail("install", "testball1").scan(message).size
  end
end
