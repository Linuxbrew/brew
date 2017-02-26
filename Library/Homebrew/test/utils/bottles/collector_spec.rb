require "utils/bottles"

describe Utils::Bottles::Collector do
  describe "#fetch_checksum_for" do
    it "returns passed tags" do
      subject[:lion] = "foo"
      subject[:mountain_lion] = "bar"
      expect(subject.fetch_checksum_for(:mountain_lion)).to eq(["bar", :mountain_lion])
    end

    it "returns nil if empty" do
      expect(subject.fetch_checksum_for(:foo)).to be nil
    end

    it "returns nil when there is no match" do
      subject[:lion] = "foo"
      expect(subject.fetch_checksum_for(:foo)).to be nil
    end

    it "returns nil when there is no match and later tag is present" do
      subject[:lion_or_later] = "foo"
      expect(subject.fetch_checksum_for(:foo)).to be nil
    end

    it "prefers exact matches" do
      subject[:lion_or_later] = "foo"
      subject[:mountain_lion] = "bar"
      expect(subject.fetch_checksum_for(:mountain_lion)).to eq(["bar", :mountain_lion])
    end

    it "finds '_or_later' tags", :needs_macos do
      subject[:lion_or_later] = "foo"
      expect(subject.fetch_checksum_for(:mountain_lion)).to eq(["foo", :lion_or_later])
      expect(subject.fetch_checksum_for(:snow_leopard)).to be nil
    end

    it "finds '_altivec' tags", :needs_macos do
      subject[:tiger_altivec] = "foo"
      expect(subject.fetch_checksum_for(:tiger_g4)).to eq(["foo", :tiger_altivec])
      expect(subject.fetch_checksum_for(:tiger_g4e)).to eq(["foo", :tiger_altivec])
      expect(subject.fetch_checksum_for(:tiger_g5)).to eq(["foo", :tiger_altivec])
      expect(subject.fetch_checksum_for(:tiger_g3)).to be nil
    end
  end
end
