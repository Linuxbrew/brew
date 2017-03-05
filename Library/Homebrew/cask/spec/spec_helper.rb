$LOAD_PATH.unshift(File.expand_path("#{ENV["HOMEBREW_REPOSITORY"]}/Library/Homebrew"))
require "test/spec_helper"

# add Homebrew-Cask to load path
$LOAD_PATH.push(HOMEBREW_LIBRARY_PATH.join("cask", "lib").to_s)

Pathname.glob(HOMEBREW_LIBRARY_PATH.join("cask", "spec", "support", "**", "*.rb")).each(&method(:require))

require "hbc"

HOMEBREW_CASK_DIRS = [
  :appdir,
  :caskroom,
  :cache,
  :prefpanedir,
  :qlplugindir,
  :servicedir,
  :binarydir,
].freeze

RSpec.configure do |config|
  config.around(:each) do |example|
    begin
      dirs = HOMEBREW_CASK_DIRS.map { |dir|
        Pathname.new(TEST_TMPDIR).join("cask-#{dir}").tap { |path|
          path.mkpath
          Hbc.public_send("#{dir}=", path)
        }
      }

      Hbc.default_tap = Tap.fetch("caskroom", "spec").tap do |tap|
        # link test casks
        FileUtils.mkdir_p tap.path.dirname
        FileUtils.ln_sf TEST_FIXTURE_DIR.join("cask"), tap.path
      end

      example.run
    ensure
      FileUtils.rm_rf dirs
    end
  end
end
