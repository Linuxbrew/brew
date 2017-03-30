require "locale"
require "os/mac"

describe OS::Mac do
  describe "::languages" do
    specify "all languages can be parsed by Locale::parse" do
      subject.languages.each do |language|
        expect { Locale.parse(language) }.not_to raise_error
      end
    end
  end

  describe "::language" do
    it "returns the first item from #languages" do
      expect(subject.language).to eq(subject.languages.first)
    end

    it "can be parsed by Locale::parse" do
      expect { Locale.parse(subject.language) }.not_to raise_error
    end
  end
end
