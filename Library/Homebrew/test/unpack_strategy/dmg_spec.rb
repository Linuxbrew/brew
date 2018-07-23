require_relative "shared_examples"

describe UnpackStrategy::Dmg, :needs_macos do
  describe "#mount" do
    subject(:dmg) { described_class.new(path) }

    let(:path) { TEST_FIXTURE_DIR/"cask/container.dmg" }

    it "does not store nil mounts for dmgs with extra data" do
      dmg.mount do |mounts|
        begin
          expect(mounts).not_to include nil
        ensure
          mounts.each(&dmg.public_method(:eject))
        end
      end
    end

    include_examples "UnpackStrategy::detect"
    include_examples "#extract", children: ["container"]
  end
end
