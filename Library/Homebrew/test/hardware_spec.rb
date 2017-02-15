require "hardware"

module Hardware
  describe CPU do
    describe "::type" do
      it "returns the current CPU's type as a symbol, or :dunno if it cannot be detected" do
        expect(
          [
            :intel,
            :ppc,
            :dunno,
          ],
        ).to include(described_class.type)
      end
    end

    describe "::family" do
      it "returns the current CPU's family name as a symbol, or :dunno if it cannot be detected" do
        skip "Needs an Intel CPU." unless described_class.intel?

        expect(
          [
            :core,
            :core2,
            :penryn,
            :nehalem,
            :arrandale,
            :sandybridge,
            :ivybridge,
            :haswell,
            :broadwell,
            :skylake,
            :kabylake,
            :dunno,
          ],
        ).to include(described_class.family)
      end
    end
  end
end
