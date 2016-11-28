require "bundler"
require "testing_env"
require "fileutils"
require "pathname"
require "formula"

class IntegrationCommandTestCase < Homebrew::TestCase
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
      HOMEBREW_PREFIX/"Caskroom",
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
    return if ENV["HOMEBREW_TEST_OFFICIAL_CMD_TAPS"]
    skip "HOMEBREW_TEST_OFFICIAL_CMD_TAPS is not set"
  end

  def needs_macos
    skip "Not on MacOS" unless OS.mac?
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
    developer = ENV["HOMEBREW_DEVELOPER"]
    Bundler.with_original_env do
      ENV["HOMEBREW_BREW_FILE"] = HOMEBREW_PREFIX/"bin/brew"
      ENV["HOMEBREW_INTEGRATION_TEST"] = cmd_id_from_args(args)
      ENV["HOMEBREW_TEST_TMPDIR"] = TEST_TMPDIR
      ENV["HOMEBREW_DEVELOPER"] = developer
      env.each_pair do |k, v|
        ENV[k] = v
      end

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
    puts "\n'brew #{args.join " "}' output: #{output}" if status.nonzero?
    assert_equal 0, status
    output
  end

  def cmd_fail(*args)
    output = cmd_output(*args)
    status = $?.exitstatus
    $stderr.puts "\n'brew #{args.join " "}'" if status.zero?
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
        url "file://#{File.expand_path("../..", __FILE__)}/tarballs/testball-0.1.tbz"
        sha256 "#{TESTBALL_SHA256}"

        option "with-foo", "Build with foo"

        def install
          (prefix/"foo"/"test").write("test") if build.with? "foo"
          prefix.install Dir["*"]
          (buildpath/"test.c").write \
            "#include <stdio.h>\\nint main(){return printf(\\"test\\");}"
          bin.mkpath
          system ENV.cc, "test.c", "-o", bin/"test"
        end

        #{content}

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
    tap.install(full_clone: false, quiet: true) unless tap.installed?
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
    "#{File.expand_path("../..", __FILE__)}/testball.rb"
  end
end
