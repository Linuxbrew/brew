describe Hbc::Container::Dmg, :cask do
  describe "#mount!" do
    it "does not store nil mounts for dmgs with extra data" do
      transmission = Hbc::CaskLoader.load(cask_path("local-transmission"))

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
