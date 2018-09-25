if ENV["HOMEBREW_TESTS_COVERAGE"]
  require "simplecov"

  formatters = [SimpleCov::Formatter::HTMLFormatter]
  if ENV["HOMEBREW_CODECOV_TOKEN"] || ENV["HOMEBREW_TRAVIS_CI"]
    require "codecov"
    formatters << SimpleCov::Formatter::Codecov
    ENV["CODECOV_TOKEN"] = ENV["HOMEBREW_CODECOV_TOKEN"]
  end

  SimpleCov.formatters = SimpleCov::Formatter::MultiFormatter.new(formatters)
end

require "rspec/its"
require "rspec/wait"
require "rspec/retry"
require "rubocop"
require "rubocop/rspec/support"
require "find"

$LOAD_PATH.push(File.expand_path("#{ENV["HOMEBREW_LIBRARY"]}/Homebrew/test/support/lib"))

require_relative "../global"

require "test/support/no_seed_progress_formatter"
require "test/support/helper/fixtures"
require "test/support/helper/formula"
require "test/support/helper/mktmpdir"
require "test/support/helper/output_as_tty"

require "test/support/helper/spec/shared_context/homebrew_cask" if OS.mac?
require "test/support/helper/spec/shared_context/integration_test"

TEST_DIRECTORIES = [
  CoreTap.instance.path/"Formula",
  HOMEBREW_CACHE,
  HOMEBREW_CACHE_FORMULA,
  HOMEBREW_CELLAR,
  HOMEBREW_LOCKS,
  HOMEBREW_LOGS,
  HOMEBREW_TEMP,
].freeze

RSpec.configure do |config|
  config.order = :random

  config.raise_errors_for_deprecations!

  config.filter_run_when_matching :focus

  config.silence_filter_announcements = true

  # TODO: when https://github.com/rspec/rspec-expectations/pull/1056
  #       makes it into a stable release:
  # config.expect_with :rspec do |c|
  #   c.max_formatted_output_length = 200
  # end

  # Never truncate output objects.
  RSpec::Support::ObjectFormatter.default_instance.max_formatted_output_length = nil

  config.include(FileUtils)

  config.include(RuboCop::RSpec::ExpectOffense)

  config.include(Test::Helper::Fixtures)
  config.include(Test::Helper::Formula)
  config.include(Test::Helper::MkTmpDir)
  config.include(Test::Helper::OutputAsTTY)

  config.before(:each, :needs_compat) do
    skip "Requires compatibility layer." if ENV["HOMEBREW_NO_COMPAT"]
  end

  config.before(:each, :needs_official_cmd_taps) do
    skip "Needs official command Taps." unless ENV["HOMEBREW_TEST_OFFICIAL_CMD_TAPS"]
  end

  config.before(:each, :needs_macos) do
    skip "Not on macOS." unless OS.mac?
  end

  config.before(:each, :needs_python) do
    skip "Python not installed." unless which("python")
  end

  config.before(:each, :needs_network) do
    skip "Requires network connection." unless ENV["HOMEBREW_TEST_ONLINE"]
  end

  config.around(:each, :needs_network) do |example|
    example.run_with_retry retry: 3, retry_wait: 1
  end

  config.before(:each, :needs_svn) do
    skip "subversion not installed." unless which "svn"
  end

  config.before(:each, :needs_unzip) do
    skip "unzip not installed." unless which("unzip")
  end

  config.around(:each) do |example|
    def find_files
      Find.find(TEST_TMPDIR)
          .reject { |f| File.basename(f) == ".DS_Store" }
          .map { |f| f.sub(TEST_TMPDIR, "") }
    end

    begin
      Tap.clear_cache

      TEST_DIRECTORIES.each(&:mkpath)

      @__homebrew_failed = Homebrew.failed?

      @__files_before_test = find_files

      @__argv = ARGV.dup
      @__env = ENV.to_hash # dup doesn't work on ENV

      unless example.metadata.key?(:focus) || ENV.key?("VERBOSE_TESTS")
        @__stdout = $stdout.clone
        @__stderr = $stderr.clone
        $stdout.reopen(File::NULL)
        $stderr.reopen(File::NULL)
      end

      example.run
    ensure
      ARGV.replace(@__argv)
      ENV.replace(@__env)

      unless example.metadata.key?(:focus) || ENV.key?("VERBOSE_TESTS")
        $stdout.reopen(@__stdout)
        $stderr.reopen(@__stderr)
        @__stdout.close
        @__stderr.close
      end

      Tab.clear_cache

      FileUtils.rm_rf [
        TEST_DIRECTORIES.map(&:children),
        *Keg::MUST_EXIST_SUBDIRECTORIES,
        HOMEBREW_LINKED_KEGS,
        HOMEBREW_PINNED_KEGS,
        HOMEBREW_PREFIX/"var",
        HOMEBREW_PREFIX/"Caskroom",
        HOMEBREW_LIBRARY/"Taps/homebrew/homebrew-cask",
        HOMEBREW_LIBRARY/"Taps/homebrew/homebrew-bar",
        HOMEBREW_LIBRARY/"Taps/homebrew/homebrew-bundle",
        HOMEBREW_LIBRARY/"Taps/homebrew/homebrew-foo",
        HOMEBREW_LIBRARY/"Taps/homebrew/homebrew-services",
        HOMEBREW_LIBRARY/"Taps/homebrew/homebrew-shallow",
        HOMEBREW_LIBRARY/"PinnedTaps",
        HOMEBREW_REPOSITORY/".git",
        CoreTap.instance.path/".git",
        CoreTap.instance.alias_dir,
        CoreTap.instance.path/"formula_renames.json",
      ]

      files_after_test = find_files

      diff = Set.new(@__files_before_test) ^ Set.new(files_after_test)
      expect(diff).to be_empty, <<~EOS
        file leak detected:
        #{diff.map { |f| "  #{f}" }.join("\n")}
      EOS

      Homebrew.failed = @__homebrew_failed
    end
  end
end

RSpec::Matchers.define_negated_matcher :not_to_output, :output
RSpec::Matchers.alias_matcher :have_failed, :be_failed
RSpec::Matchers.alias_matcher :a_string_containing, :include

RSpec::Matchers.define :a_json_string do
  match do |actual|
    begin
      JSON.parse(actual)
      true
    rescue JSON::ParseError
      false
    end
  end
end
