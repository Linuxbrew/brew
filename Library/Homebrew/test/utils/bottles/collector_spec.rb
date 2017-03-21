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
  end
end
