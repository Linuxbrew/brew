require "bundler"
require "fileutils"
require "pathname"
require "formula"
require "test/support/helper/test_case"
require "open3"

class IntegrationCommandTestCase < Homebrew::TestCase
  def setup
    super
    @cmd_id_index = 0 # Assign unique IDs to invocations of `cmd_output`.
    (HOMEBREW_PREFIX/"bin").mkpath
    FileUtils.touch HOMEBREW_PREFIX/"bin/brew"
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
    env = args.last.is_a?(Hash) ? args.pop : {}

    env.merge!(
      "HOMEBREW_BREW_FILE" => HOMEBREW_PREFIX/"bin/brew",
      "HOMEBREW_INTEGRATION_TEST" => cmd_id_from_args(args),
      "HOMEBREW_TEST_TMPDIR" => TEST_TMPDIR,
      "HOMEBREW_DEVELOPER" => ENV["HOMEBREW_DEVELOPER"],
    )

    ruby_args = [
      "-W0",
      "-I", "#{HOMEBREW_LIBRARY_PATH}/test/support/lib",
      "-I", HOMEBREW_LIBRARY_PATH.to_s,
      "-rconfig"
    ]
    ruby_args << "-rsimplecov" if ENV["HOMEBREW_TESTS_COVERAGE"]
    ruby_args << "-rtest/support/helper/integration_mocks"
    ruby_args << (HOMEBREW_LIBRARY_PATH/"brew.rb").resolved_path.to_s

    Bundler.with_original_env do
      output, status = Open3.capture2e(env, RUBY_PATH, *ruby_args, *args)
      [output.chomp, status]
    end
  end

  def cmd(*args)
    output, status = cmd_output(*args)
    assert status.success?, <<-EOS.undent
      `brew #{args.join " "}` exited with non-zero status!
      #{output}
    EOS
    output
  end

  def cmd_fail(*args)
    output, status = cmd_output(*args)
    refute status.success?, <<-EOS.undent
      `brew #{args.join " "}` exited with zero status!
      #{output}
    EOS
    output
  end

  def setup_test_formula(name, content = nil)
    formula_path = CoreTap.new.formula_dir/"#{name}.rb"

    case name
    when /^testball/
      content = <<-EOS.undent
        desc "Some test"
        homepage "https://example.com/#{name}"
        url "file://#{TEST_FIXTURE_DIR}/tarballs/testball-0.1.tbz"
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
    formula_renames.write JSON.generate(old_name => new_name)

    core_tap.path.cd do
      shutup do
        system "git", "add", "--all"
        system "git", "commit", "-m",
          "#{old_name.capitalize} has been renamed to #{new_name.capitalize}"
      end
    end
  end

  def testball
    "#{TEST_FIXTURE_DIR}/testball.rb"
  end
end
