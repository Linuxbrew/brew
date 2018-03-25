require "extend/string"

describe StringInreplaceExtension do
  subject { string.extend(described_class) }

  let(:string) { "foobar" }

  describe "#sub!" do
    it "adds an error to #errors when no replacement was made" do
      subject.sub! "not here", "test"
      expect(subject.errors).to eq(['expected replacement of "not here" with "test"'])
    end
  end
end
