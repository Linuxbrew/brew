require "test_helper"

# TODO: this test should be named after the corresponding class, once
#       that class is abstracted from installer.rb.  It makes little sense
#       to be invoking bundle_identifier off of the installer instance.
describe "Operations on staged Casks" do
  describe "bundle ID" do
    it "fetches the bundle ID from a staged cask" do
      transmission_cask = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/local-transmission.rb")
      tr_installer = Hbc::Installer.new(transmission_cask)

      shutup do
        tr_installer.install
      end
      tr_installer.bundle_identifier.must_equal("org.m0k.transmission")
    end
  end
end
