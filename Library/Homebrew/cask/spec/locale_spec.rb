require "locale"

describe Locale do
  describe "::parse" do
    it "parses a string in the correct format" do
      expect(described_class.parse("zh")).to eql(described_class.new("zh", nil, nil))
      expect(described_class.parse("zh-CN")).to eql(described_class.new("zh", "CN", nil))
      expect(described_class.parse("zh-Hans")).to eql(described_class.new("zh", nil, "Hans"))
      expect(described_class.parse("zh-CN-Hans")).to eql(described_class.new("zh", "CN", "Hans"))
    end

    context "raises a ParserError when given" do
      it "an empty string" do
        expect { described_class.parse("") }.to raise_error(Locale::ParserError)
      end

      it "a string in a wrong format" do
        expect { described_class.parse("zh_CN_Hans") }.to raise_error(Locale::ParserError)
        expect { described_class.parse("zhCNHans") }.to raise_error(Locale::ParserError)
        expect { described_class.parse("zh-CN_Hans") }.to raise_error(Locale::ParserError)
        expect { described_class.parse("zhCN") }.to raise_error(Locale::ParserError)
        expect { described_class.parse("zh_Hans") }.to raise_error(Locale::ParserError)
      end
    end
  end

  describe "::new" do
    it "raises an ArgumentError when all arguments are nil" do
      expect { described_class.new(nil, nil, nil) }.to raise_error(ArgumentError)
    end

    it "raises a ParserError when one of the arguments does not match the locale format" do
      expect { described_class.new("ZH", nil, nil) }.to raise_error(Locale::ParserError)
      expect { described_class.new(nil, "cn", nil) }.to raise_error(Locale::ParserError)
      expect { described_class.new(nil, nil, "hans") }.to raise_error(Locale::ParserError)
    end
  end

  subject { described_class.new("zh", "CN", "Hans") }

  describe "#include?" do
    it { is_expected.to include("zh") }
    it { is_expected.to include("zh-CN") }
    it { is_expected.to include("CN") }
    it { is_expected.to include("CN-Hans") }
    it { is_expected.to include("Hans") }
    it { is_expected.to include("zh-CN-Hans") }
  end

  describe "#eql?" do
    subject { described_class.new("zh", "CN", "Hans") }

    context "all parts match" do
      it { is_expected.to eql("zh-CN-Hans") }
      it { is_expected.to eql(subject) }
    end

    context "only some parts match" do
      it { is_expected.to_not eql("zh") }
      it { is_expected.to_not eql("zh-CN") }
      it { is_expected.to_not eql("CN") }
      it { is_expected.to_not eql("CN-Hans") }
      it { is_expected.to_not eql("Hans") }
    end

    it "does not raise if 'other' cannot be parsed" do
      expect { subject.eql?("zh_CN_Hans") }.not_to raise_error
      expect(subject.eql?("zh_CN_Hans")).to be false
    end
  end
end
