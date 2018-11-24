require "open3"

RSpec::Matchers.define_negated_matcher :be_a_failure, :be_a_success

RSpec.shared_context "integration test" do
  extend RSpec::Matchers::DSL

  matcher :be_a_success do
    match do |actual|
      status = actual.is_a?(Proc) ? actual.call : actual
      status.respond_to?(:success?) && status.success?
    end

    def supports_block_expectations?
      true
    end

    # It needs to be nested like this:
    #
    #   expect {
    #     expect {
    #       # command
    #     }.to be_a_success
    #   }.to output(something).to_stdout
    #
    # rather than this:
    #
    #   expect {
    #     expect {
    #       # command
    #     }.to output(something).to_stdout
    #   }.to be_a_success
    #
    def expects_call_stack_jump?
      true
    end
  end

  around do |example|
    begin
      (HOMEBREW_PREFIX/"bin").mkpath
      FileUtils.touch HOMEBREW_PREFIX/"bin/brew"

      example.run
    ensure
      FileUtils.rm HOMEBREW_PREFIX/"bin/brew"
      FileUtils.rmdir HOMEBREW_PREFIX/"bin"
    end
  end

  # Generate unique ID to be able to
  # properly merge coverage results.
  def command_id_from_args(args)
    @command_count ||= 0
    pretty_args = args.join(" ").gsub(TEST_TMPDIR, "@TMPDIR@")
    file_and_line = caller.second
                          .sub(/(.*\d+):.*/, '\1')
                          .sub("#{HOMEBREW_LIBRARY_PATH}/test/", "")
    "#{file_and_line}:brew #{pretty_args}:#{@command_count += 1}"
  end

  # Runs a `brew` command with the test configuration
  # and with coverage reporting enabled.
  def brew(*args)
    env = args.last.is_a?(Hash) ? args.pop : {}

    # Avoid warnings when HOMEBREW_PREFIX/bin is not in PATH.
    path = [
      env["PATH"],
      (HOMEBREW_PREFIX/"bin").realpath.to_s,
      ENV["PATH"],
    ].compact.join(File::PATH_SEPARATOR)

    env.merge!(
      "PATH"                      => path,
      "HOMEBREW_PATH"             => path,
      "HOMEBREW_BREW_FILE"        => HOMEBREW_PREFIX/"bin/brew",
      "HOMEBREW_INTEGRATION_TEST" => command_id_from_args(args),
      "HOMEBREW_TEST_TMPDIR"      => TEST_TMPDIR,
      "HOMEBREW_DEVELOPER"        => ENV["HOMEBREW_DEVELOPER"],
      "GEM_HOME"                  => nil,
    )

    @ruby_args ||= begin
      ruby_args = [
        "-W0",
        "-I", $LOAD_PATH.join(File::PATH_SEPARATOR)
      ]
      if ENV["HOMEBREW_TESTS_COVERAGE"]
        simplecov_spec = Gem.loaded_specs["simplecov"]
        specs = [simplecov_spec]
        simplecov_spec.runtime_dependencies.each do |dep|
          begin
            specs += dep.to_specs
          rescue Gem::LoadError => e
            onoe e
          end
        end
        libs = specs.flat_map do |spec|
          full_gem_path = spec.full_gem_path
          # full_require_paths isn't available in RubyGems < 2.2.
          spec.require_paths.map do |lib|
            next lib if lib.include?(full_gem_path)

            "#{full_gem_path}/#{lib}"
          end
        end
        libs.each { |lib| ruby_args << "-I" << lib }
        ruby_args << "-rsimplecov"
      end
      ruby_args << "-rtest/support/helper/integration_mocks"
      ruby_args << (HOMEBREW_LIBRARY_PATH/"brew.rb").resolved_path.to_s
    end

    Bundler.with_clean_env do
      stdout, stderr, status = Open3.capture3(env, RUBY_PATH, *@ruby_args, *args)
      $stdout.print stdout
      $stderr.print stderr
      status
    end
  end

  def setup_test_formula(name, content = nil)
    case name
    when /^testball/
      tarball = if OS.linux?
        TEST_FIXTURE_DIR/"tarballs/testball-0.1-linux.tbz"
      else
        TEST_FIXTURE_DIR/"tarballs/testball-0.1.tbz"
      end
      content = <<~RUBY
        desc "Some test"
        homepage "https://example.com/#{name}"
        url "file://#{tarball}"
        sha256 "#{tarball.sha256}"

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
      RUBY
    when "foo"
      content = <<~RUBY
        url "https://example.com/#{name}-1.0"
      RUBY
    when "bar"
      content = <<~RUBY
        url "https://example.com/#{name}-1.0"
        depends_on "foo"
      RUBY
    when "patchelf"
      content = <<~RUBY
        url "https://example.com/#{name}-1.0"
      RUBY
    end

    Formulary.core_path(name).tap do |formula_path|
      formula_path.write <<~RUBY
        class #{Formulary.class_s(name)} < Formula
          #{content}
        end
      RUBY
    end
  end

  def setup_remote_tap(name)
    Tap.fetch(name).tap do |tap|
      next if tap.installed?
      full_name = Tap.fetch(name).full_name
      # Check to see if the original Homebrew process has taps we can use.
      system_tap_path = Pathname("#{ENV["HOMEBREW_LIBRARY"]}/Taps/#{full_name}")
      if system_tap_path.exist?
        system "git", "clone", "--shared", system_tap_path, tap.path
        system "git", "-C", tap.path, "checkout", "master"
      else
        tap.install(full_clone: false, quiet: true)
      end
    end
  end

  def install_and_rename_coretap_formula(old_name, new_name)
    CoreTap.instance.path.cd do |tap_path|
      system "git", "init"
      system "git", "add", "--all"
      system "git", "commit", "-m",
        "#{old_name.capitalize} has not yet been renamed"

      brew "install", old_name

      (tap_path/"Formula/#{old_name}.rb").unlink
      (tap_path/"formula_renames.json").write JSON.generate(old_name => new_name)

      system "git", "add", "--all"
      system "git", "commit", "-m",
        "#{old_name.capitalize} has been renamed to #{new_name.capitalize}"
    end
  end

  def testball
    "#{TEST_FIXTURE_DIR}/testball.rb"
  end
end

RSpec.configure do |config|
  config.include_context "integration test", :integration_test
end
