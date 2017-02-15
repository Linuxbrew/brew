require "find"
require "pathname"
require "rspec/its"
require "rspec/wait"
require "set"

if ENV["HOMEBREW_TESTS_COVERAGE"]
  require "simplecov"
end

$LOAD_PATH.unshift(File.expand_path("#{ENV["HOMEBREW_LIBRARY"]}/Homebrew"))
$LOAD_PATH.unshift(File.expand_path("#{ENV["HOMEBREW_LIBRARY"]}/Homebrew/test/support/lib"))

require "global"
require "tap"

require "test/support/helper/shutup"
require "test/support/helper/fixtures"
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
  config.include(Test::Helper::Shutup)
  config.include(Test::Helper::Fixtures)
  config.before(:each) do |example|
    if example.metadata[:needs_macos]
      skip "not on macOS" unless OS.mac?
    end

    if example.metadata[:needs_python]
      skip "Python not installed." unless which("python")
    end
  end
  config.around(:each) do |example|
    begin
      TEST_DIRECTORIES.each(&:mkpath)

      @__homebrew_failed = Homebrew.failed?

      @__files_before_test = Find.find(TEST_TMPDIR).map { |f| f.sub(TEST_TMPDIR, "") }

      @__argv = ARGV.dup
      @__env = ENV.to_hash # dup doesn't work on ENV

      example.run
    ensure
      ARGV.replace(@__argv)
      ENV.replace(@__env)

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
        HOMEBREW_LIBRARY/"Taps/homebrew/homebrew-bundle",
        HOMEBREW_LIBRARY/"Taps/homebrew/homebrew-foo",
        HOMEBREW_LIBRARY/"Taps/homebrew/homebrew-services",
        HOMEBREW_LIBRARY/"Taps/homebrew/homebrew-shallow",
        HOMEBREW_REPOSITORY/".git",
        CoreTap.instance.path/".git",
        CoreTap.instance.alias_dir,
        CoreTap.instance.path/"formula_renames.json",
      ]

      files_after_test = Find.find(TEST_TMPDIR).map { |f| f.sub(TEST_TMPDIR, "") }

      diff = Set.new(@__files_before_test) ^ Set.new(files_after_test)
      expect(diff).to be_empty, <<-EOS.undent
        file leak detected:
        #{diff.map { |f| "  #{f}" }.join("\n")}
      EOS

      Homebrew.failed = @__homebrew_failed
    end
  end
end

RSpec::Matchers.alias_matcher :have_failed, :be_failed
