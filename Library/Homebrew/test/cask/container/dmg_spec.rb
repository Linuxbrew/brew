describe Hbc::Container::Dmg, :cask do
  describe "#mount!" do
    it "does not store nil mounts for dmgs with extra data" do
      transmission = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/local-transmission.rb")

      dmg = Hbc::Container::Dmg.new(
        transmission,
        Pathname(transmission.url.path),
        Hbc::SystemCommand,
      )

      begin
        dmg.mount!
        expect(dmg.mounts).not_to include nil
      ensure
        dmg.eject!
      end
    end
  end
end
