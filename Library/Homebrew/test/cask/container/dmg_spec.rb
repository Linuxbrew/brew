describe Hbc::Container::Dmg, :cask do
  describe "#mount!" do
    it "does not store nil mounts for dmgs with extra data" do
      transmission = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/local-transmission.rb")

      dmg = Hbc::Container::Dmg.new(
        transmission,
        Pathname(transmission.url.path),
        Hbc::SystemCommand,
      )

      dmg.mount do |mounts|
        begin
          expect(mounts).not_to include nil
        ensure
          mounts.each(&dmg.public_method(:eject))
        end
      end
    end
  end
end
