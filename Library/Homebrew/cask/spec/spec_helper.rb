require "pathname"
require "rspec/its"
require "rspec/wait"

if ENV["HOMEBREW_TESTS_COVERAGE"]
  require "simplecov"
end

# add Homebrew to load path
$LOAD_PATH.unshift(File.expand_path("#{ENV["HOMEBREW_REPOSITORY"]}/Library/Homebrew"))
$LOAD_PATH.unshift(File.expand_path("#{ENV["HOMEBREW_REPOSITORY"]}/Library/Homebrew/test/support/lib"))

require "global"

# add Homebrew-Cask to load path
$LOAD_PATH.push(HOMEBREW_LIBRARY_PATH.join("cask", "lib").to_s)

require "test/support/helper/shutup"

Pathname.glob(HOMEBREW_LIBRARY_PATH.join("cask", "spec", "support", "**", "*.rb")).each(&method(:require))

require "hbc"

# create and override default directories
Hbc.appdir = Pathname.new(TEST_TMPDIR).join("Applications").tap(&:mkpath)
Hbc.cache.mkpath
Hbc.caskroom = Hbc.default_caskroom.tap(&:mkpath)
Hbc.default_tap = Tap.fetch("caskroom", "spec").tap do |tap|
  # link test casks
  FileUtils.mkdir_p tap.path.dirname
  FileUtils.ln_s TEST_FIXTURE_DIR.join("cask"), tap.path
end

# pretend that the caskroom/cask Tap is installed
FileUtils.ln_s Pathname.new(ENV["HOMEBREW_LIBRARY"]).join("Taps", "caskroom", "homebrew-cask"), Tap.fetch("caskroom", "cask").path

HOMEBREW_CASK_DIRS = [
  :appdir,
  :caskroom,
  :prefpanedir,
  :qlplugindir,
  :servicedir,
  :binarydir,
].freeze

RSpec.configure do |config|
  config.order = :random
  config.include(Test::Helper::Shutup)
  config.around(:each) do |example|
    begin
      @__dirs = HOMEBREW_CASK_DIRS.map { |dir|
        Pathname.new(TEST_TMPDIR).join(dir.to_s).tap { |path|
          path.mkpath
          Hbc.public_send("#{dir}=", path)
        }
      }

      @__argv = ARGV.dup
      @__env = ENV.to_hash # dup doesn't work on ENV

      example.run
    ensure
      ARGV.replace(@__argv)
      ENV.replace(@__env)

      FileUtils.rm_rf @__dirs.map(&:children)
    end
  end
end
