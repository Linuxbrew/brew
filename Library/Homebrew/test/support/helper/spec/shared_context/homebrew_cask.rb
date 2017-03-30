$LOAD_PATH.push(HOMEBREW_LIBRARY_PATH.join("cask", "lib").to_s)

require "hbc"

require "test/support/helper/cask/fake_system_command"
require "test/support/helper/cask/install_helper"
require "test/support/helper/cask/never_sudo_system_command"

HOMEBREW_CASK_DIRS = [
  :appdir,
  :caskroom,
  :cache,
  :prefpanedir,
  :qlplugindir,
  :servicedir,
  :binarydir,
].freeze

RSpec.shared_context "Homebrew-Cask" do
  around(:each) do |example|
    begin
      dirs = HOMEBREW_CASK_DIRS.map do |dir|
        Pathname.new(TEST_TMPDIR).join("cask-#{dir}").tap do |path|
          path.mkpath
          Hbc.public_send("#{dir}=", path)
        end
      end

      Hbc.default_tap = Tap.fetch("caskroom", "spec").tap do |tap|
        FileUtils.mkdir_p tap.path.dirname
        FileUtils.ln_sf TEST_FIXTURE_DIR.join("cask"), tap.path
      end

      example.run
    ensure
      FileUtils.rm_rf dirs
      Hbc.default_tap.path.unlink
      FileUtils.rm_rf Hbc.default_tap.path.parent
    end
  end
end

RSpec.configure do |config|
  config.include_context "Homebrew-Cask", :cask
end
