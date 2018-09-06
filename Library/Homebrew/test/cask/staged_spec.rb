# TODO: this test should be named after the corresponding class, once
#       that class is abstracted from installer.rb.  It makes little sense
#       to be invoking bundle_identifier off of the installer instance.
describe "Operations on staged Casks", :cask do
  describe "bundle ID" do
    let(:cask) { Cask::CaskLoader.load(cask_path("local-transmission")) }
    let(:installer) { Cask::Installer.new(cask) }

    it "fetches the bundle ID from a staged cask" do
      installer.install
      expect(installer.bundle_identifier).to eq("org.m0k.transmission")
    end
  end
end
