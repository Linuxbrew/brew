require "find"
require "pathname"
require "rspec/its"
require "rspec/wait"
require "set"

if ENV["HOMEBREW_TESTS_COVERAGE"]
  require "simplecov"

  if ENV["CODECOV_TOKEN"] || ENV["TRAVIS"]
    require "codecov"
    SimpleCov.formatter = SimpleCov::Formatter::Codecov
  end
end

$LOAD_PATH.unshift(File.expand_path("#{ENV["HOMEBREW_LIBRARY"]}/Homebrew"))
$LOAD_PATH.unshift(File.expand_path("#{ENV["HOMEBREW_LIBRARY"]}/Homebrew/test/support/lib"))

require "global"
require "tap"

require "test/support/helper/fixtures"
require "test/support/helper/formula"
require "test/support/helper/mktmpdir"
require "test/support/helper/output_as_tty"
require "test/support/helper/rubocop"

require "test/support/helper/spec/shared_context/homebrew_cask" if OS.mac?
require "test/support/helper/spec/shared_context/integration_test"

TEST_DIRECTORIES = [
  CoreTap.instance.path/"Formula",
  HOMEBREW_CACHE,
  HOMEBREW_CACHE_FORMULA,
  HOMEBREW_CELLAR,
  HOMEBREW_LOCK_DIR,
  HOMEBREW_LOGS,
  HOMEBREW_TEMP,
].freeze

RSpec.configure do |config|
  config.order = :random

  config.filter_run_when_matching :focus

  config.include(Test::Helper::Fixtures)
  config.include(Test::Helper::Formula)
  config.include(Test::Helper::MkTmpDir)
  config.include(Test::Helper::OutputAsTTY)
  config.include(Test::Helper::RuboCop)

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

  config.around(:each) do |example|
    def find_files
      Find.find(TEST_TMPDIR)
          .reject { |f| File.basename(f) == ".DS_Store" }
          .map { |f| f.sub(TEST_TMPDIR, "") }
    end

    begin
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
        HOMEBREW_LINKED_KEGS,
        HOMEBREW_PINNED_KEGS,
        HOMEBREW_PREFIX/".git",
        HOMEBREW_PREFIX/"bin",
        HOMEBREW_PREFIX/"share",
        HOMEBREW_PREFIX/"opt",
        HOMEBREW_PREFIX/"Caskroom",
        HOMEBREW_LIBRARY/"Taps/caskroom",
        HOMEBREW_LIBRARY/"Taps/homebrew/homebrew-bar",
        HOMEBREW_LIBRARY/"Taps/homebrew/homebrew-bundle",
        HOMEBREW_LIBRARY/"Taps/homebrew/homebrew-foo",
        HOMEBREW_LIBRARY/"Taps/homebrew/homebrew-services",
        HOMEBREW_LIBRARY/"Taps/homebrew/homebrew-shallow",
        HOMEBREW_REPOSITORY/".git",
        CoreTap.instance.path/".git",
        CoreTap.instance.alias_dir,
        CoreTap.instance.path/"formula_renames.json",
      ]

      files_after_test = find_files

      diff = Set.new(@__files_before_test) ^ Set.new(files_after_test)
      expect(diff).to be_empty, <<-EOS.undent
        file leak detected:
        #{diff.map { |f| "  #{f}" }.join("\n")}
      EOS

      Homebrew.failed = @__homebrew_failed
    end
  end
end

RSpec::Matchers.define_negated_matcher :not_to_output, :output
RSpec::Matchers.alias_matcher :have_failed, :be_failed
