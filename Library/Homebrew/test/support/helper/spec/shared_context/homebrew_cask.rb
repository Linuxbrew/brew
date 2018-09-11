require "cask/all"

require "test/support/helper/cask/fake_system_command"
require "test/support/helper/cask/install_helper"
require "test/support/helper/cask/never_sudo_system_command"

HOMEBREW_CASK_DIRS = {
  :appdir      => Pathname.new(TEST_TMPDIR).join("cask-appdir"),
  :prefpanedir => Pathname.new(TEST_TMPDIR).join("cask-prefpanedir"),
  :qlplugindir => Pathname.new(TEST_TMPDIR).join("cask-qlplugindir"),
  :servicedir  => Pathname.new(TEST_TMPDIR).join("cask-servicedir"),
}.freeze

RSpec.shared_context "Homebrew Cask", :needs_macos do
  before do
    HOMEBREW_CASK_DIRS.each do |method, path|
      allow(Cask::Config.global).to receive(method).and_return(path)
    end
  end

  around do |example|
    third_party_tap = Tap.fetch("third-party", "tap")
    begin
      HOMEBREW_CASK_DIRS.values.each(&:mkpath)

      Cask::Config.global.binarydir.mkpath

      Tap.default_cask_tap.tap do |tap|
        FileUtils.mkdir_p tap.path.dirname
        FileUtils.ln_sf TEST_FIXTURE_DIR.join("cask"), tap.path
      end

      third_party_tap.tap do |tap|
        FileUtils.mkdir_p tap.path.dirname
        FileUtils.ln_sf TEST_FIXTURE_DIR.join("third-party"), tap.path
      end

      example.run
    ensure
      FileUtils.rm_rf HOMEBREW_CASK_DIRS.values
      FileUtils.rm_rf [Cask::Config.global.binarydir, Cask::Caskroom.path, Cask::Cache.path]
      Tap.default_cask_tap.path.unlink
      third_party_tap.path.unlink
      FileUtils.rm_rf third_party_tap.path.parent
    end
  end
end

RSpec.configure do |config|
  config.include_context "Homebrew Cask", :cask
end
