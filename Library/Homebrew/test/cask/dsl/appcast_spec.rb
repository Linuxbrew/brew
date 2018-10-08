require "cmd/cask"

describe Cask::DSL::Appcast do
  subject { described_class.new(url, params) }

  let(:url) { "https://example.com" }
  let(:uri) { URI(url) }
  let(:params) { {} }

  describe "#to_s" do
    it "returns the parsed URI string" do
      expect(subject.to_s).to eq("https://example.com")
    end
  end

  describe "#to_yaml" do
    let(:yaml) { [uri, params].to_yaml }

    context "with empty parameters" do
      it "returns an YAML serialized array composed of the URI and parameters" do
        expect(subject.to_yaml).to eq(yaml)
      end
    end
  end
end
