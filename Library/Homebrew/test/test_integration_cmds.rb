require "bundler"
require "testing_env"
require "fileutils"
require "pathname"
require "formula"

class IntegrationCommandTests < Homebrew::TestCase
  def setup
    @formula_files = []
    @cmd_id_index = 0 # Assign unique IDs to invocations of `cmd_output`.
    (HOMEBREW_PREFIX/"bin").mkpath
    FileUtils.touch HOMEBREW_PREFIX/"bin/brew"
  end

  def teardown
    (HOMEBREW_PREFIX/"bin").rmtree
    @formula_files.each(&:unlink)
  end

  def needs_test_cmd_taps
    unless ENV["HOMEBREW_TEST_OFFICIAL_CMD_TAPS"]
      skip "HOMEBREW_TEST_OFFICIAL_CMD_TAPS is not set"
    end
  end

  def cmd_id_from_args(args)
    args_pretty = args.join(" ").gsub(TEST_TMPDIR, "@TMPDIR@")
    test_pretty = "#{self.class.name}\##{name}.#{@cmd_id_index += 1}"
    "[#{test_pretty}] brew #{args_pretty}"
  end

  def cmd_output(*args)
    # 1.8-compatible way of writing def cmd_output(*args, **env)
    env = args.last.is_a?(Hash) ? args.pop : {}
    cmd_args = %W[
      -W0
      -I#{HOMEBREW_LIBRARY_PATH}/test/lib
      -rconfig
    ]
    if ENV["HOMEBREW_TESTS_COVERAGE"]
      # This is needed only because we currently use a patched version of
      # simplecov, and gems installed through git are not available without
      # requiring bundler/setup first. See also the comment in test/Gemfile.
      # Remove this line when we'll switch back to a stable simplecov release.
      cmd_args << "-rbundler/setup"
      cmd_args << "-rsimplecov"
    end
    cmd_args << "-rintegration_mocks"
    cmd_args << (HOMEBREW_LIBRARY_PATH/"../brew.rb").resolved_path.to_s
    cmd_args += args
    Bundler.with_original_env do
      ENV["HOMEBREW_BREW_FILE"] = HOMEBREW_PREFIX/"bin/brew"
      ENV["HOMEBREW_INTEGRATION_TEST"] = cmd_id_from_args(args)
      ENV["HOMEBREW_TEST_TMPDIR"] = TEST_TMPDIR
      env.each_pair { |k, v| ENV[k] = v }

      read, write = IO.pipe
      begin
        pid = fork do
          read.close
          $stdout.reopen(write)
          $stderr.reopen(write)
          write.close
          exec RUBY_PATH, *cmd_args
        end
        write.close
        read.read.chomp
      ensure
        Process.wait(pid)
        read.close
      end
    end
  end

  def cmd(*args)
    output = cmd_output(*args)
    status = $?.exitstatus
    puts "\n#{output}" if status != 0
    assert_equal 0, status
    output
  end

  def cmd_fail(*args)
    output = cmd_output(*args)
    status = $?.exitstatus
    $stderr.puts "\n#{output}" if status != 1
    assert_equal 1, status
    output
  end

  def setup_test_formula(name, content = nil)
    formula_path = CoreTap.new.formula_dir/"#{name}.rb"
    @formula_files << formula_path

    case name
    when "testball"
      content = <<-EOS.undent
        desc "Some test"
        homepage "https://example.com/#{name}"
        url "file://#{File.expand_path("..", __FILE__)}/tarballs/#{name}-0.1.tbz"
        sha256 "#{TESTBALL_SHA256}"

        option "with-foo", "Build with foo"
        #{content}

        def install
          (prefix/"foo"/"test").write("test") if build.with? "foo"
          prefix.install Dir["*"]
        end

        # something here
      EOS
    when "foo"
      content = <<-EOS.undent
        url "https://example.com/#{name}-1.0"
      EOS
    when "bar"
      content = <<-EOS.undent
        url "https://example.com/#{name}-1.0"
        depends_on "foo"
      EOS
    end

    formula_path.write <<-EOS.undent
      class #{Formulary.class_s(name)} < Formula
        #{content}
      end
    EOS

    formula_path
  end

  def setup_remote_tap(name)
    tap = Tap.fetch name
    tap.install(:full_clone => false, :quiet => true) unless tap.installed?
    tap
  end

  def testball
    "#{File.expand_path("..", __FILE__)}/testball.rb"
  end

  def test_prefix
    assert_equal HOMEBREW_PREFIX.to_s,
                 cmd("--prefix")
  end

  def test_version
    assert_match HOMEBREW_VERSION.to_s,
                 cmd("--version")
  end

  def test_cache
    assert_equal HOMEBREW_CACHE.to_s,
                 cmd("--cache")
  end

  def test_cache_formula
    assert_match %r{#{HOMEBREW_CACHE}/testball-},
                 cmd("--cache", testball)
  end

  def test_cellar
    assert_equal HOMEBREW_CELLAR.to_s,
                 cmd("--cellar")
  end

  def test_cellar_formula
    assert_match "#{HOMEBREW_CELLAR}/testball",
                 cmd("--cellar", testball)
  end

  def test_cleanup
    assert_equal HOMEBREW_CACHE.to_s,
                 cmd("cleanup")
  end

  def test_env
    assert_match %r{CMAKE_PREFIX_PATH="#{HOMEBREW_PREFIX}[:"]},
                 cmd("--env")
  end

  def test_prefix_formula
    assert_match "#{HOMEBREW_CELLAR}/testball",
                 cmd("--prefix", testball)
  end

  def test_repository
    assert_match HOMEBREW_REPOSITORY.to_s,
                 cmd("--repository")
  end

  def test_repository
    assert_match "#{HOMEBREW_LIBRARY}/Taps/foo/homebrew-bar",
                 cmd("--repository", "foo/bar")
  end

  def test_help
    assert_match "Example usage:\n",
                 cmd_fail # Generic help (empty argument list).
    assert_match "Unknown command: command-that-does-not-exist",
                 cmd_fail("help", "command-that-does-not-exist")
    assert_match(/^brew cat /,
                 cmd_fail("cat")) # Missing formula argument triggers help.

    assert_match "Example usage:\n",
                 cmd("help") # Generic help.
    assert_match(/^brew cat /,
                 cmd("help", "cat")) # Internal command (documented, Ruby).
    assert_match(/^brew update /,
                 cmd("help", "update")) # Internal command (documented, Shell).
    if ARGV.homebrew_developer?
      assert_match "Example usage:\n",
                   cmd("help", "test-bot") # Internal developer command (undocumented).
    end
  end

  def test_config
    assert_match "HOMEBREW_VERSION: #{HOMEBREW_VERSION}",
                 cmd("config")
  end

  def test_install
    assert_match "#{HOMEBREW_CELLAR}/testball/0.1", cmd("install", testball)
  ensure
    cmd("uninstall", "--force", testball)
    cmd("cleanup", "--force", "--prune=all")
  end

  def test_bottle
    cmd("install", "--build-bottle", testball)
    assert_match "Formula not from core or any taps",
                 cmd_fail("bottle", "--no-revision", testball)

    setup_test_formula "testball"

    # `brew bottle` should not fail with dead symlink
    # https://github.com/Homebrew/legacy-homebrew/issues/49007
    (HOMEBREW_CELLAR/"testball/0.1").cd do
      FileUtils.ln_s "not-exist", "symlink"
    end
    assert_match(/testball-0\.1.*\.bottle\.tar\.gz/,
                  cmd_output("bottle", "--no-revision", "testball"))
  ensure
    cmd("uninstall", "--force", "testball")
    cmd("cleanup", "--force", "--prune=all")
    FileUtils.rm_f Dir["testball-0.1*.bottle.tar.gz"]
  end

  def test_uninstall
    cmd("install", testball)
    assert_match "Uninstalling testball", cmd("uninstall", "--force", testball)
  ensure
    cmd("cleanup", "--force", "--prune=all")
  end

  def test_cleanup
    (HOMEBREW_CACHE/"test").write "test"
    assert_match "#{HOMEBREW_CACHE}/test", cmd("cleanup", "--prune=all")
  ensure
    FileUtils.rm_f HOMEBREW_CACHE/"test"
  end

  def test_readall
    formula_file = setup_test_formula "testball"
    alias_file = CoreTap.new.alias_dir/"foobar"
    alias_file.parent.mkpath
    FileUtils.ln_s formula_file, alias_file
    cmd("readall", "--aliases", "--syntax")
    cmd("readall", "homebrew/core")
  ensure
    alias_file.parent.rmtree
  end

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
    assert_match "homebrew/versions", cmd("tap", "--list-official")
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
  ensure
    path.rmtree
  end

  def test_missing
    setup_test_formula "foo"
    setup_test_formula "bar"

    (HOMEBREW_CELLAR/"bar/1.0").mkpath
    assert_match "foo", cmd("missing")
  ensure
    (HOMEBREW_CELLAR/"bar").rmtree
  end

  def test_doctor
    assert_match "This is an integration test",
                 cmd_fail("doctor", "check_integration_test")
  end

  def test_command
    assert_equal "#{HOMEBREW_LIBRARY_PATH}/cmd/info.rb",
                 cmd("command", "info")

    assert_match "Unknown command",
                 cmd_fail("command", "I-don't-exist")
  end

  def test_commands
    assert_match "Built-in commands",
                 cmd("commands")
  end

  def test_cat
    formula_file = setup_test_formula "testball"
    assert_equal formula_file.read.chomp, cmd("cat", "testball")
  end

  def test_desc
    setup_test_formula "testball"

    assert_equal "testball: Some test", cmd("desc", "testball")
    assert_match "Pick one, and only one", cmd_fail("desc", "--search", "--name")
    assert_match "You must provide a search term", cmd_fail("desc", "--search")

    desc_cache = HOMEBREW_CACHE/"desc_cache.json"
    refute_predicate desc_cache, :exist?, "Cached file should not exist"

    cmd("desc", "--description", "testball")
    assert_predicate desc_cache, :exist?, "Cached file should not exist"
  ensure
    desc_cache.unlink
  end

  def test_edit
    (HOMEBREW_REPOSITORY/".git").mkpath
    setup_test_formula "testball"

    assert_match "# something here",
                 cmd("edit", "testball", "HOMEBREW_EDITOR" => "/bin/cat")
  ensure
    (HOMEBREW_REPOSITORY/".git").unlink
  end

  def test_sh
    assert_match "Your shell has been configured",
                 cmd("sh", "SHELL" => "/usr/bin/true")
  end

  def test_info
    setup_test_formula "testball"

    assert_match "testball: stable 0.1",
                 cmd("info", "testball")
  end

  def test_tap_readme
    assert_match "brew install homebrew/foo/<formula>",
                 cmd("tap-readme", "foo", "--verbose")
    readme = HOMEBREW_LIBRARY/"Taps/homebrew/homebrew-foo/README.md"
    assert readme.exist?, "The README should be created"
  ensure
    (HOMEBREW_LIBRARY/"Taps/homebrew/homebrew-foo").rmtree
  end

  def test_unpack
    setup_test_formula "testball"

    mktmpdir do |path|
      cmd "unpack", "testball", "--destdir=#{path}"
      assert File.directory?("#{path}/testball-0.1"),
        "The tarball should be unpacked"
    end
  ensure
    FileUtils.rm_f HOMEBREW_CACHE/"testball-0.1.tbz"
  end

  def test_options
    setup_test_formula "testball", <<-EOS.undent
      depends_on "bar" => :recommended
    EOS

    assert_equal "--with-foo\n\tBuild with foo\n--without-bar\n\tBuild without bar support",
      cmd_output("options", "testball").chomp
  end

  def test_outdated
    setup_test_formula "testball"
    (HOMEBREW_CELLAR/"testball/0.0.1/foo").mkpath

    assert_equal "testball", cmd("outdated")
  ensure
    FileUtils.rm_rf HOMEBREW_CELLAR/"testball"
  end

  def test_upgrade
    setup_test_formula "testball"
    (HOMEBREW_CELLAR/"testball/0.0.1/foo").mkpath

    cmd("upgrade")
    assert((HOMEBREW_CELLAR/"testball/0.1").directory?,
      "The latest version directory should be created")
  ensure
    cmd("uninstall", "--force", testball)
    cmd("cleanup", "--force", "--prune=all")
  end

  def test_linkapps
    home_dir = Pathname.new(mktmpdir)
    (home_dir/"Applications").mkpath

    setup_test_formula "testball"

    source_dir = HOMEBREW_CELLAR/"testball/0.1/TestBall.app"
    source_dir.mkpath
    assert_match "Linking: #{source_dir}",
      cmd("linkapps", "--local", "HOME" => home_dir)
  ensure
    home_dir.rmtree
    (HOMEBREW_CELLAR/"testball").rmtree
  end

  def test_unlinkapps
    home_dir = Pathname.new(mktmpdir)
    apps_dir = home_dir/"Applications"
    apps_dir.mkpath

    setup_test_formula "testball"

    source_app = (HOMEBREW_CELLAR/"testball/0.1/TestBall.app")
    source_app.mkpath

    FileUtils.ln_s source_app, "#{apps_dir}/TestBall.app"

    assert_match "Unlinking: #{apps_dir}/TestBall.app",
      cmd("unlinkapps", "--local", "HOME" => home_dir)
  ensure
    home_dir.rmtree
    (HOMEBREW_CELLAR/"testball").rmtree
  end

  def test_pin_unpin
    setup_test_formula "testball"
    (HOMEBREW_CELLAR/"testball/0.0.1/foo").mkpath

    cmd("pin", "testball")
    cmd("upgrade")
    refute((HOMEBREW_CELLAR/"testball/0.1").directory?,
      "The latest version directory should NOT be created")

    cmd("unpin", "testball")
    cmd("upgrade")
    assert((HOMEBREW_CELLAR/"testball/0.1").directory?,
      "The latest version directory should be created")
  ensure
    cmd("uninstall", "--force", testball)
    cmd("cleanup", "--force", "--prune=all")
  end

  def test_reinstall
    setup_test_formula "testball"

    cmd("install", "testball", "--with-foo")
    foo_dir = HOMEBREW_CELLAR/"testball/0.1/foo"
    assert foo_dir.exist?
    foo_dir.rmtree
    assert_match "Reinstalling testball with --with-foo",
      cmd("reinstall", "testball")
    assert foo_dir.exist?
  ensure
    cmd("uninstall", "--force", "testball")
    cmd("cleanup", "--force", "--prune=all")
  end

  def test_home
    setup_test_formula "testball"

    assert_equal HOMEBREW_WWW,
                 cmd("home", "HOMEBREW_BROWSER" => "echo")
    assert_equal Formula["testball"].homepage,
                 cmd("home", "testball", "HOMEBREW_BROWSER" => "echo")
  end

  def test_list
    formulae = %w[bar foo qux]
    formulae.each do |f|
      (HOMEBREW_CELLAR/"#{f}/1.0/somedir").mkpath
    end

    assert_equal formulae.join("\n"),
                 cmd("list")
  ensure
    formulae.each do |f|
      (HOMEBREW_CELLAR/"#{f}").rmtree
    end
  end

  def test_create
    url = "file://#{File.expand_path("..", __FILE__)}/tarballs/testball-0.1.tbz"
    cmd("create", url, "HOMEBREW_EDITOR" => "/bin/cat")

    formula_file = CoreTap.new.formula_dir/"testball.rb"
    assert formula_file.exist?, "The formula source should have been created"
    assert_match %(sha256 "#{TESTBALL_SHA256}"), formula_file.read
  ensure
    formula_file.unlink
    cmd("cleanup", "--force", "--prune=all")
  end

  def test_fetch
    setup_test_formula "testball"

    cmd("fetch", "testball")
    assert((HOMEBREW_CACHE/"testball-0.1.tbz").exist?,
      "The tarball should have been cached")
  ensure
    cmd("cleanup", "--force", "--prune=all")
  end

  def test_deps
    setup_test_formula "foo"
    setup_test_formula "bar"
    setup_test_formula "baz", <<-EOS.undent
      url "https://example.com/baz-1.0"
      depends_on "bar"
    EOS

    assert_equal "", cmd("deps", "foo")
    assert_equal "foo", cmd("deps", "bar")
    assert_equal "bar\nfoo", cmd("deps", "baz")
  end

  def test_uses
    setup_test_formula "foo"
    setup_test_formula "bar"
    setup_test_formula "baz", <<-EOS.undent
      url "https://example.com/baz-1.0"
      depends_on "bar"
    EOS

    assert_equal "", cmd("uses", "baz")
    assert_equal "baz", cmd("uses", "bar")
    assert_equal "bar\nbaz", cmd("uses", "--recursive", "foo")
  end

  def test_log
    FileUtils.cd HOMEBREW_REPOSITORY do
      shutup do
        system "git", "init"
        system "git", "commit", "--allow-empty", "-m", "This is a test commit"
      end
    end
    assert_match "This is a test commit", cmd("log")
  ensure
    (HOMEBREW_REPOSITORY/".git").rmtree
  end

  def test_log_formula
    core_tap = CoreTap.new
    setup_test_formula "testball"

    core_tap.path.cd do
      shutup do
        system "git", "init"
        system "git", "add", "--all"
        system "git", "commit", "-m", "This is a test commit for Testball"
      end
    end

    core_tap_url = "file://#{core_tap.path}"
    shallow_tap = Tap.fetch("homebrew", "shallow")
    shutup do
      system "git", "clone", "--depth=1", core_tap_url, shallow_tap.path
    end

    assert_match "This is a test commit for Testball",
                 cmd("log", "#{shallow_tap}/testball")
    assert_predicate shallow_tap.path/".git/shallow", :exist?,
                     "A shallow clone should have been created."
  ensure
    (core_tap.path/".git").rmtree
    shallow_tap.path.rmtree
  end

  def test_leaves
    setup_test_formula "foo"
    setup_test_formula "bar"
    assert_equal "", cmd("leaves")

    (HOMEBREW_CELLAR/"foo/0.1/somedir").mkpath
    assert_equal "foo", cmd("leaves")

    (HOMEBREW_CELLAR/"bar/0.1/somedir").mkpath
    assert_equal "bar", cmd("leaves")
  ensure
    (HOMEBREW_CELLAR/"foo").rmtree
    (HOMEBREW_CELLAR/"bar").rmtree
  end

  def test_prune
    share = (HOMEBREW_PREFIX/"share")

    (share/"pruneable/directory/here").mkpath
    (share/"notpruneable/file").write "I'm here"
    FileUtils.ln_s "/i/dont/exist/no/really/i/dont", share/"pruneable_symlink"

    assert_match %r{Would remove \(empty directory\): .*/pruneable/directory/here},
      cmd("prune", "--dry-run")
    assert_match "Pruned 1 symbolic links and 3 directories",
      cmd("prune")
    refute((share/"pruneable").directory?)
    assert((share/"notpruneable").directory?)
    refute((share/"pruneable_symlink").symlink?)

    # Inexact match because only if ~/Applications exists, will this output one
    # more line with contents `No apps unlinked from /Users/<user/Applications`.
    assert_match "Nothing pruned\nNo apps unlinked from /Applications",
      cmd("prune", "--verbose")
  ensure
    share.rmtree
  end

  def test_custom_command
    mktmpdir do |path|
      cmd = "int-test-#{rand}"
      file = "#{path}/brew-#{cmd}"

      File.open(file, "w") { |f| f.write "#!/bin/sh\necho 'I am #{cmd}'\n" }
      FileUtils.chmod 0777, file

      assert_match "I am #{cmd}",
        cmd(cmd, "PATH" => "#{path}#{File::PATH_SEPARATOR}#{ENV["PATH"]}")
    end
  end

  def test_search
    setup_test_formula "testball"
    desc_cache = HOMEBREW_CACHE/"desc_cache.json"
    refute_predicate desc_cache, :exist?, "Cached file should not exist"

    assert_match "testball", cmd("search")
    assert_match "testball", cmd("search", "testball")
    assert_match "testball", cmd("search", "homebrew/homebrew-core/testball")
    assert_match "testball", cmd("search", "--desc", "Some test")

    flags = {
      "macports" => "https://www.macports.org/ports.php?by=name&substr=testball",
      "fink" => "http://pdb.finkproject.org/pdb/browse.php?summary=testball",
      "debian" => "https://packages.debian.org/search?keywords=testball&searchon=names&suite=all&section=all",
      "opensuse" => "https://software.opensuse.org/search?q=testball",
      "fedora" => "https://admin.fedoraproject.org/pkgdb/packages/%2Atestball%2A/",
      "ubuntu" => "http://packages.ubuntu.com/search?keywords=testball&searchon=names&suite=all&section=all",
    }

    flags.each do |flag, url|
      assert_equal url, cmd("search", "--#{flag}",
        "testball", "HOMEBREW_BROWSER" => "echo")
    end

    assert_predicate desc_cache, :exist?, "Cached file should exist"
  ensure
    desc_cache.unlink
  end

  def test_bundle
    needs_test_cmd_taps
    setup_remote_tap("homebrew/bundle")
    HOMEBREW_REPOSITORY.cd do
      shutup do
        system "git", "init"
        system "git", "commit", "--allow-empty", "-m", "This is a test commit"
      end
    end

    mktmpdir do |path|
      FileUtils.touch "#{path}/Brewfile"
      Dir.chdir path do
        assert_equal "The Brewfile's dependencies are satisfied.",
          cmd("bundle", "check")
      end
    end
  ensure
    FileUtils.rm_rf HOMEBREW_REPOSITORY/".git"
    FileUtils.rm_rf HOMEBREW_LIBRARY/"Taps/homebrew/homebrew-bundle"
  end

  def test_cask
    needs_test_cmd_taps
    setup_remote_tap("caskroom/cask")
    cmd("cask", "list")
  ensure
    FileUtils.rm_rf HOMEBREW_LIBRARY/"Taps/caskroom"
    FileUtils.rm_rf HOMEBREW_PREFIX/"share"
  end

  def test_services
    needs_test_cmd_taps
    setup_remote_tap("homebrew/services")
    assert_equal "Warning: No services available to control with `brew services`",
      cmd("services", "list")
  ensure
    FileUtils.rm_rf HOMEBREW_LIBRARY/"Taps/homebrew/homebrew-services"
  end
end
