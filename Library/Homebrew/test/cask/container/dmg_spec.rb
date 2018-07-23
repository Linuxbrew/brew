describe Hbc::Container::Dmg, :cask do
  describe "#mount" do
    let(:transmission) { Hbc::CaskLoader.load(cask_path("local-transmission")) }
    subject(:dmg) { described_class.new(transmission, Pathname(transmission.url.path)) }

    it "does not store nil mounts for dmgs with extra data" do
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
