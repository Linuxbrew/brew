require "checksum"

describe Checksum do
  describe "#empty?" do
    subject { described_class.new(:sha256, "") }
    it { is_expected.to be_empty }
  end

  describe "#==" do
    subject { described_class.new(:sha256, TEST_SHA256) }
    let(:other) { described_class.new(:sha256, TEST_SHA256) }
    let(:other_reversed) { described_class.new(:sha256, TEST_SHA256.reverse) }
    let(:other_sha1) { described_class.new(:sha1, TEST_SHA1) }

    it { is_expected.to eq(other) }
    it { is_expected.not_to eq(other_reversed) }
    it { is_expected.not_to eq(other_sha1) }
  end
end
