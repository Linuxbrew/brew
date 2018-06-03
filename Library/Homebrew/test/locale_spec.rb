require "locale"

describe Locale do
  describe "::parse" do
    it "parses a string in the correct format" do
      expect(described_class.parse("zh")).to eql(described_class.new("zh", nil, nil))
      expect(described_class.parse("zh-CN")).to eql(described_class.new("zh", "CN", nil))
      expect(described_class.parse("zh-Hans")).to eql(described_class.new("zh", nil, "Hans"))
      expect(described_class.parse("zh-CN-Hans")).to eql(described_class.new("zh", "CN", "Hans"))
    end

    it "correctly parses a string with a UN M.49 region code" do
      expect(described_class.parse("es-419")).to eql(described_class.new("es", "419", nil))
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

  describe "#include?" do
    subject { described_class.new("zh", "CN", "Hans") }

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
      it { is_expected.not_to eql("zh") }
      it { is_expected.not_to eql("zh-CN") }
      it { is_expected.not_to eql("CN") }
      it { is_expected.not_to eql("CN-Hans") }
      it { is_expected.not_to eql("Hans") }
    end

    it "does not raise if 'other' cannot be parsed" do
      expect { subject.eql?("zh_CN_Hans") }.not_to raise_error
      expect(subject.eql?("zh_CN_Hans")).to be false
    end
  end

  describe "#detect" do
    let(:locale_groups) { [["zh"], ["zh-TW"]] }

    it "finds best matching language code, independent of order" do
      expect(described_class.new("zh", "TW", nil).detect(locale_groups)).to eql(["zh-TW"])
      expect(described_class.new("zh", "TW", nil).detect(locale_groups.reverse)).to eql(["zh-TW"])
      expect(described_class.new("zh", "CN", "Hans").detect(locale_groups)).to eql(["zh"])
    end
  end
end
