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

Pathname.glob(HOMEBREW_LIBRARY_PATH.join("cask", "spec", "support", "*.rb")).each(&method(:require))

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

RSpec.configure do |config|
  config.order = :random
  config.include(Test::Helper::Shutup)
  config.include(FileMatchers)
end
