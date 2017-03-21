require "testing_env"
require "testing_env"

class IntegrationCommandTestTap < IntegrationCommandTestCase
  def test_tap
    path = Tap::TAP_DIRECTORY/"homebrew/homebrew-foo"
    path.mkpath
    path.cd do
      shutup do
        system "git", "init"
        system "git", "remote", "add", "origin", "https://github.com/Homebrew/homebrew-foo"
        FileUtils.touch "readme"
        system "git", "add", "--all"
        system "git", "commit", "-m", "init"
      end
    end

    assert_match "homebrew/foo", cmd("tap")
    assert_match "homebrew/science", cmd("tap", "--list-official")
    assert_match "2 taps", cmd("tap-info")
    assert_match "https://github.com/Homebrew/homebrew-foo", cmd("tap-info", "homebrew/foo")
    assert_match "https://github.com/Homebrew/homebrew-foo", cmd("tap-info", "--json=v1", "--installed")
    assert_match "Pinned homebrew/foo", cmd("tap-pin", "homebrew/foo")
    assert_match "homebrew/foo", cmd("tap", "--list-pinned")
    assert_match "Unpinned homebrew/foo", cmd("tap-unpin", "homebrew/foo")
    assert_match "Tapped", cmd("tap", "homebrew/bar", path/".git")
    assert_match "Untapped", cmd("untap", "homebrew/bar")
    assert_equal "", cmd("tap", "homebrew/bar", path/".git", "-q", "--full")
    assert_match "Untapped", cmd("untap", "homebrew/bar")
  end
end

class TapTest < Homebrew::TestCase
  include FileUtils

  def setup
    super
    @path = Tap::TAP_DIRECTORY/"homebrew/homebrew-foo"
    @path.mkpath
    @tap = Tap.new("Homebrew", "foo")
  end

  def setup_tap_files
    @formula_file = @path/"Formula/foo.rb"
    @formula_file.write <<-EOS.undent
      class Foo < Formula
        url "https://example.com/foo-1.0.tar.gz"
      end
    EOS
    @alias_file = @path/"Aliases/bar"
    @alias_file.parent.mkpath
    ln_s @formula_file, @alias_file
    (@path/"formula_renames.json").write <<-EOS.undent
     { "oldname": "foo" }
    EOS
    (@path/"tap_migrations.json").write <<-EOS.undent
     { "removed-formula": "homebrew/foo" }
    EOS
    @cmd_file = @path/"cmd/brew-tap-cmd.rb"
    @cmd_file.parent.mkpath
    touch @cmd_file
    chmod 0755, @cmd_file
    @manpage_file = @path/"man/man1/brew-tap-cmd.1"
    @manpage_file.parent.mkpath
    touch @manpage_file
  end

  def setup_git_repo
    @path.cd do
      shutup do
        system "git", "init"
        system "git", "remote", "add", "origin", "https://github.com/Homebrew/homebrew-foo"
        system "git", "add", "--all"
        system "git", "commit", "-m", "init"
      end
    end
  end

  def test_fetch
    assert_kind_of CoreTap, Tap.fetch("Homebrew", "homebrew")
    tap = Tap.fetch("Homebrew", "foo")
    assert_kind_of Tap, tap
    assert_equal "homebrew/foo", tap.name

    assert_match "Invalid tap name",
                 assert_raises { Tap.fetch("foo") }.message
    assert_match "Invalid tap name",
                 assert_raises { Tap.fetch("homebrew/homebrew/bar") }.message
    assert_match "Invalid tap name",
                 assert_raises { Tap.fetch("homebrew", "homebrew/baz") }.message
  ensure
    Tap.clear_cache
  end

  def test_names
    assert_equal ["homebrew/core", "homebrew/foo"], Tap.names.sort
  end

  def test_attributes
    assert_equal "Homebrew", @tap.user
    assert_equal "foo", @tap.repo
    assert_equal "homebrew/foo", @tap.name
    assert_equal @path, @tap.path
    assert_predicate @tap, :installed?
    assert_predicate @tap, :official?
    refute_predicate @tap, :core_tap?
  end

  def test_issues_url
    t = Tap.new("someone", "foo")
    path = Tap::TAP_DIRECTORY/"someone/homebrew-foo"
    path.mkpath
    cd path do
      shutup { system "git", "init" }
      system "git", "remote", "add", "origin",
        "https://github.com/someone/homebrew-foo"
    end
    assert_equal "https://github.com/someone/homebrew-foo/issues", t.issues_url
    assert_equal "https://github.com/Homebrew/homebrew-foo/issues", @tap.issues_url

    (Tap::TAP_DIRECTORY/"someone/homebrew-no-git").mkpath
    assert_nil Tap.new("someone", "no-git").issues_url
  ensure
    path.parent.rmtree
  end

  def test_files
    setup_tap_files

    assert_equal [@formula_file], @tap.formula_files
    assert_equal ["homebrew/foo/foo"], @tap.formula_names
    assert_equal [@alias_file], @tap.alias_files
    assert_equal ["homebrew/foo/bar"], @tap.aliases
    assert_equal @tap.alias_table, "homebrew/foo/bar" => "homebrew/foo/foo"
    assert_equal @tap.alias_reverse_table, "homebrew/foo/foo" => ["homebrew/foo/bar"]
    assert_equal @tap.formula_renames, "oldname" => "foo"
    assert_equal @tap.tap_migrations, "removed-formula" => "homebrew/foo"
    assert_equal [@cmd_file], @tap.command_files
    assert_kind_of Hash, @tap.to_hash
    assert_equal true, @tap.formula_file?(@formula_file)
    assert_equal true, @tap.formula_file?("Formula/foo.rb")
    assert_equal false, @tap.formula_file?("bar.rb")
    assert_equal false, @tap.formula_file?("Formula/baz.sh")
  end

  def test_remote
    setup_git_repo

    assert_equal "https://github.com/Homebrew/homebrew-foo", @tap.remote
    assert_raises(TapUnavailableError) { Tap.new("Homebrew", "bar").remote }
    refute_predicate @tap, :custom_remote?

    services_tap = Tap.new("Homebrew", "services")
    services_tap.path.mkpath
    services_tap.path.cd do
      shutup do
        system "git", "init"
        system "git", "remote", "add", "origin", "https://github.com/Homebrew/homebrew-services"
      end
    end
    refute_predicate services_tap, :private?
  end

  def test_remote_not_git_repo
    assert_nil @tap.remote
  end

  def test_remote_git_not_available
    setup_git_repo
    Utils.stubs(:git_available?).returns(false)
    assert_nil @tap.remote
  end

  def test_git_variant
    touch @path/"README"
    setup_git_repo

    assert_equal "0453e16c8e3fac73104da50927a86221ca0740c2", @tap.git_head
    assert_equal "0453", @tap.git_short_head
    assert_match(/\A\d+ .+ ago\Z/, @tap.git_last_commit)
    assert_equal "2017-01-22", @tap.git_last_commit_date
  end

  def test_private_remote
    skip "HOMEBREW_GITHUB_API_TOKEN is required" unless GitHub.api_credentials
    assert_predicate @tap, :private?
  end

  def test_install_tap_already_tapped_error
    setup_git_repo
    already_tapped_tap = Tap.new("Homebrew", "foo")
    assert_equal true, already_tapped_tap.installed?
    assert_raises(TapAlreadyTappedError) { already_tapped_tap.install }
  end

  def test_install_tap_remote_match_already_tapped_error
    setup_git_repo
    already_tapped_tap = Tap.new("Homebrew", "foo")
    assert_equal true, already_tapped_tap.installed?
    right_remote = @tap.remote
    assert_raises(TapAlreadyTappedError) { already_tapped_tap.install clone_target: right_remote }
  end

  def test_install_tap_remote_mismatch_error
    setup_git_repo
    already_tapped_tap = Tap.new("Homebrew", "foo")
    touch @tap.path/".git/shallow"
    assert_equal true, already_tapped_tap.installed?
    wrong_remote = "#{@tap.remote}-oops"
    assert_raises(TapRemoteMismatchError) { already_tapped_tap.install clone_target: wrong_remote, full_clone: true }
  end

  def test_install_tap_already_unshallow_error
    setup_git_repo
    already_tapped_tap = Tap.new("Homebrew", "foo")
    assert_raises(TapAlreadyUnshallowError) { already_tapped_tap.install full_clone: true }
  end

  def test_uninstall_tap_unavailable_error
    tap = Tap.new("Homebrew", "bar")
    assert_raises(TapUnavailableError) { tap.uninstall }
  end

  def test_install_git_error
    tap = Tap.new("user", "repo")
    assert_raises(ErrorDuringExecution) do
      shutup { tap.install clone_target: "file:///not/existed/remote/url" }
    end
    refute_predicate tap, :installed?
    refute_predicate Tap::TAP_DIRECTORY/"user", :exist?
  end

  def test_install_and_uninstall
    setup_tap_files
    setup_git_repo

    tap = Tap.new("Homebrew", "bar")
    shutup { tap.install clone_target: @tap.path/".git" }
    assert_predicate tap, :installed?
    assert_predicate HOMEBREW_PREFIX/"share/man/man1/brew-tap-cmd.1", :file?
    shutup { tap.uninstall }
    refute_predicate tap, :installed?
    refute_predicate HOMEBREW_PREFIX/"share/man/man1/brew-tap-cmd.1", :exist?
    refute_predicate HOMEBREW_PREFIX/"share/man/man1", :exist?
  end

  def test_pin_and_unpin
    refute_predicate @tap, :pinned?
    assert_raises(TapPinStatusError) { @tap.unpin }
    @tap.pin
    assert_predicate @tap, :pinned?
    assert_raises(TapPinStatusError) { @tap.pin }
    @tap.unpin
    refute_predicate @tap, :pinned?
  end

  def test_config
    setup_git_repo

    assert_nil @tap.config["foo"]
    @tap.config["foo"] = "bar"
    assert_equal "bar", @tap.config["foo"]
    @tap.config["foo"] = nil
    assert_nil @tap.config["foo"]
  end
end

class CoreTapTest < Homebrew::TestCase
  include FileUtils

  def setup
    super
    @repo = CoreTap.new
  end

  def test_attributes
    assert_equal "Homebrew", @repo.user
    assert_equal "core", @repo.repo
    assert_equal "homebrew/core", @repo.name
    assert_equal [], @repo.command_files
    assert_predicate @repo, :installed?
    refute_predicate @repo, :pinned?
    assert_predicate @repo, :official?
    assert_predicate @repo, :core_tap?
  end

  def test_forbidden_operations
    assert_raises(RuntimeError) { @repo.uninstall }
    assert_raises(RuntimeError) { @repo.pin }
    assert_raises(RuntimeError) { @repo.unpin }
  end

  def test_files
    @formula_file = @repo.formula_dir/"foo.rb"
    @formula_file.write <<-EOS.undent
      class Foo < Formula
        url "https://example.com/foo-1.0.tar.gz"
      end
    EOS
    @alias_file = @repo.alias_dir/"bar"
    @alias_file.parent.mkpath
    ln_s @formula_file, @alias_file

    assert_equal [@formula_file], @repo.formula_files
    assert_equal ["foo"], @repo.formula_names
    assert_equal [@alias_file], @repo.alias_files
    assert_equal ["bar"], @repo.aliases
    assert_equal @repo.alias_table, "bar" => "foo"
    assert_equal @repo.alias_reverse_table, "foo" => ["bar"]
  end
end
