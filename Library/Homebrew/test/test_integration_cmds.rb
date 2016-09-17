require "bundler"
require "testing_env"
require "fileutils"
require "pathname"
require "formula"

class IntegrationCommandTests < Homebrew::TestCase
  def setup
    @cmd_id_index = 0 # Assign unique IDs to invocations of `cmd_output`.
    (HOMEBREW_PREFIX/"bin").mkpath
    FileUtils.touch HOMEBREW_PREFIX/"bin/brew"
  end

  def teardown
    coretap = CoreTap.new
    paths_to_delete = [
      HOMEBREW_LINKED_KEGS,
      HOMEBREW_PINNED_KEGS,
      HOMEBREW_CELLAR.children,
      HOMEBREW_CACHE.children,
      HOMEBREW_LOCK_DIR.children,
      HOMEBREW_LOGS.children,
      HOMEBREW_TEMP.children,
      HOMEBREW_PREFIX/"bin",
      HOMEBREW_PREFIX/"share",
      HOMEBREW_PREFIX/"opt",
      HOMEBREW_LIBRARY/"Taps/caskroom",
      HOMEBREW_LIBRARY/"Taps/homebrew/homebrew-bundle",
      HOMEBREW_LIBRARY/"Taps/homebrew/homebrew-foo",
      HOMEBREW_LIBRARY/"Taps/homebrew/homebrew-services",
      HOMEBREW_LIBRARY/"Taps/homebrew/homebrew-shallow",
      HOMEBREW_REPOSITORY/".git",
      coretap.path/".git",
      coretap.alias_dir,
      coretap.formula_dir.children,
      coretap.path/"formula_renames.json",
    ].flatten
    FileUtils.rm_rf paths_to_delete
  end

  def needs_test_cmd_taps
    unless ENV["HOMEBREW_TEST_OFFICIAL_CMD_TAPS"]
      skip "HOMEBREW_TEST_OFFICIAL_CMD_TAPS is not set"
    end
  end

  def needs_osx
    skip "Not on OS X" unless OS.mac?
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
    cmd_args << (HOMEBREW_LIBRARY_PATH/"brew.rb").resolved_path.to_s
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
    puts "\n#{output}" if status.nonzero?
    assert_equal 0, status
    output
  end

  def cmd_fail(*args)
    output = cmd_output(*args)
    status = $?.exitstatus
    $stderr.puts "\n#{output}" if status.zero?
    refute_equal 0, status
    output
  end

  def setup_test_formula(name, content = nil)
    formula_path = CoreTap.new.formula_dir/"#{name}.rb"

    case name
    when /^testball/
      content = <<-EOS.undent
        desc "Some test"
        homepage "https://example.com/#{name}"
        url "file://#{File.expand_path("..", __FILE__)}/tarballs/testball-0.1.tbz"
        sha256 "#{TESTBALL_SHA256}"

        option "with-foo", "Build with foo"
        #{content}

        def install
          (prefix/"foo"/"test").write("test") if build.with? "foo"
          prefix.install Dir["*"]
          (buildpath/"test.c").write \
            "#include <stdio.h>\\nint main(){return printf(\\"test\\");}"
          bin.mkpath
          system ENV.cc, "test.c", "-o", bin/"test"
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

  def install_and_rename_coretap_formula(old_name, new_name)
    core_tap = CoreTap.new
    core_tap.path.cd do
      shutup do
        system "git", "init"
        system "git", "add", "--all"
        system "git", "commit", "-m",
          "#{old_name.capitalize} has not yet been renamed"
      end
    end

    cmd("install", old_name)
    (core_tap.path/"Formula/#{old_name}.rb").unlink
    formula_renames = core_tap.path/"formula_renames.json"
    formula_renames.write Utils::JSON.dump(old_name => new_name)

    core_tap.path.cd do
      shutup do
        system "git", "add", "--all"
        system "git", "commit", "-m",
          "#{old_name.capitalize} has been renamed to #{new_name.capitalize}"
      end
    end
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

  def test_env
    assert_match(/CMAKE_PREFIX_PATH="#{Regexp.escape(HOMEBREW_PREFIX)}[:"]/,
                 cmd("--env"))
  end

  def test_env_bash
    assert_match(/export CMAKE_PREFIX_PATH="#{Regexp.quote(HOMEBREW_PREFIX.to_s)}"/,
                 cmd("--env", "--shell=bash"))
  end

  def test_env_fish
    assert_match(/set [-]gx CMAKE_PREFIX_PATH "#{Regexp.quote(HOMEBREW_PREFIX.to_s)}"/,
                 cmd("--env", "--shell=fish"))
  end

  def test_env_csh
    assert_match(/setenv CMAKE_PREFIX_PATH #{Regexp.quote(HOMEBREW_PREFIX.to_s)};/,
                 cmd("--env", "--shell=tcsh"))
  end

  def test_env_plain
    assert_match(/CMAKE_PREFIX_PATH: #{Regexp.quote(HOMEBREW_PREFIX)}/,
                 cmd("--env", "--plain"))
  end

  def test_prefix_formula
    assert_match "#{HOMEBREW_CELLAR}/testball",
                 cmd("--prefix", testball)
  end

  def test_repository
    assert_match HOMEBREW_REPOSITORY.to_s,
                 cmd("--repository")
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
    assert_match(/^brew test-bot /,
                 cmd("help", "test-bot")) # Internal developer command (documented, Ruby).
  end

  def test_config
    assert_match "HOMEBREW_VERSION: #{HOMEBREW_VERSION}",
                 cmd("config")
  end

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

  def test_bottle
    cmd("install", "--build-bottle", testball)
    assert_match "Formula not from core or any taps",
                 cmd_fail("bottle", "--no-rebuild", testball)

    setup_test_formula "testball"

    # `brew bottle` should not fail with dead symlink
    # https://github.com/Homebrew/legacy-homebrew/issues/49007
    (HOMEBREW_CELLAR/"testball/0.1").cd do
      FileUtils.ln_s "not-exist", "symlink"
    end
    assert_match(/testball-0\.1.*\.bottle\.tar\.gz/,
                  cmd_output("bottle", "--no-rebuild", "testball"))
  ensure
    FileUtils.rm_f Dir["testball-0.1*.bottle.tar.gz"]
  end

  def test_uninstall
    cmd("install", testball)
    assert_match "Uninstalling testball", cmd("uninstall", "--force", testball)
  end

  def test_cleanup
    (HOMEBREW_CACHE/"test").write "test"
    assert_match "#{HOMEBREW_CACHE}/test", cmd("cleanup", "--prune=all")
  end

  def test_readall
    formula_file = setup_test_formula "testball"
    alias_file = CoreTap.new.alias_dir/"foobar"
    alias_file.parent.mkpath
    FileUtils.ln_s formula_file, alias_file
    cmd("readall", "--aliases", "--syntax")
    cmd("readall", "homebrew/core")
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
  end

  def test_missing
    setup_test_formula "foo"
    setup_test_formula "bar"

    (HOMEBREW_CELLAR/"bar/1.0").mkpath
    assert_match "foo", cmd("missing")
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
  end

  def test_edit
    (HOMEBREW_REPOSITORY/".git").mkpath
    setup_test_formula "testball"

    assert_match "# something here",
                 cmd("edit", "testball", "HOMEBREW_EDITOR" => "/bin/cat")
  end

  def test_sh
    assert_match "Your shell has been configured",
                 cmd("sh", "SHELL" => which("true"))
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
  end

  def test_unpack
    setup_test_formula "testball"

    mktmpdir do |path|
      cmd "unpack", "testball", "--destdir=#{path}"
      assert File.directory?("#{path}/testball-0.1"),
        "The tarball should be unpacked"
    end
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
  end

  def test_upgrade
    setup_test_formula "testball"
    (HOMEBREW_CELLAR/"testball/0.0.1/foo").mkpath

    cmd("upgrade")
    assert((HOMEBREW_CELLAR/"testball/0.1").directory?,
      "The latest version directory should be created")
  end

  def test_linkapps
    home_dir = Pathname.new(mktmpdir)
    (home_dir/"Applications").mkpath

    setup_test_formula "testball"

    source_dir = HOMEBREW_CELLAR/"testball/0.1/TestBall.app"
    source_dir.mkpath
    assert_match "Linking: #{source_dir}",
      cmd("linkapps", "--local", "HOME" => home_dir)
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
  end

  def test_reinstall_pinned
    setup_test_formula "testball"

    HOMEBREW_CELLAR.join("testball/0.1").mkpath
    HOMEBREW_PINNED_KEGS.mkpath
    FileUtils.ln_s HOMEBREW_CELLAR.join("testball/0.1"), HOMEBREW_PINNED_KEGS/"testball"

    assert_match "testball is pinned. You must unpin it to reinstall.", cmd("reinstall", "testball")

    HOMEBREW_PINNED_KEGS.rmtree
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
  end

  def test_create
    url = "file://#{File.expand_path("..", __FILE__)}/tarballs/testball-0.1.tbz"
    cmd("create", url, "HOMEBREW_EDITOR" => "/bin/cat")

    formula_file = CoreTap.new.formula_dir/"testball.rb"
    assert formula_file.exist?, "The formula source should have been created"
    assert_match %(sha256 "#{TESTBALL_SHA256}"), formula_file.read
  end

  def test_fetch
    setup_test_formula "testball"

    cmd("fetch", "testball")
    assert((HOMEBREW_CACHE/"testball-0.1.tbz").exist?,
      "The tarball should have been cached")
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
  end

  def test_leaves
    setup_test_formula "foo"
    setup_test_formula "bar"
    assert_equal "", cmd("leaves")

    (HOMEBREW_CELLAR/"foo/0.1/somedir").mkpath
    assert_equal "foo", cmd("leaves")

    (HOMEBREW_CELLAR/"bar/0.1/somedir").mkpath
    assert_equal "bar", cmd("leaves")
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

    assert_match "Nothing pruned", cmd("prune", "--verbose")
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
  end

  def test_cask
    needs_test_cmd_taps
    needs_osx
    setup_remote_tap("caskroom/cask")
    cmd("cask", "list")
  end

  def test_services
    needs_test_cmd_taps
    needs_osx
    setup_remote_tap("homebrew/services")
    assert_equal "Warning: No services available to control with `brew services`",
      cmd("services", "list")
  end

  def test_link
    assert_match "This command requires a keg argument", cmd_fail("link")

    setup_test_formula "testball1"
    cmd("install", "testball1")
    cmd("link", "testball1")

    cmd("unlink", "testball1")
    assert_match "Would link", cmd("link", "--dry-run", "testball1")
    assert_match "Would remove",
      cmd("link", "--dry-run", "--overwrite", "testball1")
    assert_match "Linking", cmd("link", "testball1")

    setup_test_formula "testball2", <<-EOS.undent
      keg_only "just because"
    EOS
    cmd("install", "testball2")
    assert_match "testball2 is keg-only", cmd("link", "testball2")
  end

  def test_unlink
    setup_test_formula "testball"

    cmd("install", "testball")
    assert_match "Would remove", cmd("unlink", "--dry-run", "testball")
  end

  def test_irb
    assert_match "'v8'.f # => instance of the v8 formula",
      cmd("irb", "--examples")

    setup_test_formula "testball"

    irb_test = HOMEBREW_TEMP/"irb-test.rb"
    irb_test.write <<-EOS.undent
      "testball".f
      :testball.f
      exit
    EOS

    assert_match "Interactive Homebrew Shell", cmd("irb", irb_test)
  end

  def test_pull_offline
    assert_match "You meant `git pull --rebase`.", cmd_fail("pull", "--rebase")
    assert_match "This command requires at least one argument", cmd_fail("pull")
    assert_match "Not a GitHub pull request or commit",
      cmd_fail("pull", "0")
  end

  def test_pull
    skip "Requires network connection" if ENV["HOMEBREW_NO_GITHUB_API"]

    core_tap = CoreTap.new
    core_tap.path.cd do
      shutup do
        system "git", "init"
        system "git", "checkout", "-b", "new-branch"
      end
    end

    assert_match "Testing URLs require `--bottle`!",
      cmd_fail("pull", "https://bot.brew.sh/job/Homebrew\%20Testing/1028/")
    assert_match "Current branch is new-branch",
      cmd_fail("pull", "1")
    assert_match "No changed formulae found to bump",
      cmd_fail("pull", "--bump", "8")
    assert_match "Can only bump one changed formula",
      cmd_fail("pull", "--bump",
        "https://api.github.com/repos/Homebrew/homebrew-core/pulls/122")
    assert_match "Patch failed to apply",
      cmd_fail("pull", "https://github.com/Homebrew/homebrew-core/pull/1")
  end

  def test_analytics
    HOMEBREW_REPOSITORY.cd do
      shutup do
        system "git", "init"
      end
    end

    assert_match "Analytics is disabled (by HOMEBREW_NO_ANALYTICS)",
      cmd("analytics", "HOMEBREW_NO_ANALYTICS" => "1")

    cmd("analytics", "off")
    assert_match "Analytics is disabled",
      cmd("analytics", "HOMEBREW_NO_ANALYTICS" => nil)

    cmd("analytics", "on")
    assert_match "Analytics is enabled", cmd("analytics",
      "HOMEBREW_NO_ANALYTICS" => nil)

    assert_match "Invalid usage", cmd_fail("analytics", "on", "off")
    assert_match "Invalid usage", cmd_fail("analytics", "testball")
    cmd("analytics", "regenerate-uuid")
  end

  def test_migrate
    setup_test_formula "testball1"
    setup_test_formula "testball2"
    assert_match "Invalid usage", cmd_fail("migrate")
    assert_match "No available formula with the name \"testball\"",
      cmd_fail("migrate", "testball")
    assert_match "testball1 doesn't replace any formula",
      cmd_fail("migrate", "testball1")

    install_and_rename_coretap_formula "testball1", "testball2"
    assert_match "Migrating testball1 to testball2", cmd("migrate", "testball1")
    (HOMEBREW_CELLAR/"testball1").unlink
    assert_match "Error: No such keg", cmd_fail("migrate", "testball1")
  end

  def test_switch
    assert_match "Usage: brew switch <name> <version>", cmd_fail("switch")
    assert_match "testball not found", cmd_fail("switch", "testball", "0.1")

    setup_test_formula "testball", <<-EOS.undent
      keg_only "just because"
    EOS

    cmd("install", "testball")
    testball_rack = HOMEBREW_CELLAR/"testball"
    FileUtils.cp_r testball_rack/"0.1", testball_rack/"0.2"

    cmd("switch", "testball", "0.2")
    assert_match "testball does not have a version \"0.3\"",
      cmd_fail("switch", "testball", "0.3")
  end

  def test_test_formula
    assert_match "This command requires a formula argument", cmd_fail("test")
    assert_match "Testing requires the latest version of testball",
      cmd_fail("test", testball)

    cmd("install", testball)
    assert_match "testball defines no test", cmd_fail("test", testball)

    setup_test_formula "testball_copy", <<-EOS.undent
      head "https://github.com/example/testball2.git"

      devel do
        url "file://#{File.expand_path("..", __FILE__)}/tarballs/testball-0.1.tbz"
        sha256 "#{TESTBALL_SHA256}"
      end

      keg_only "just because"

      test do
      end
    EOS

    cmd("install", "testball_copy")
    assert_match "Testing testball_copy", cmd("test", "--HEAD", "testball_copy")
    assert_match "Testing testball_copy", cmd("test", "--devel", "testball_copy")
  end
end
