require "searchable"

describe Searchable do
  subject { ary.extend(described_class) }

  let(:ary) { ["with-dashes"] }

  describe "#search" do
    context "when given a block" do
      let(:ary) { [["with-dashes", "withdashes"]] }

      it "searches by the selected argument" do
        expect(subject.search(/withdashes/) { |_, short_name| short_name }).not_to be_empty
        expect(subject.search(/withdashes/) { |long_name, _| long_name }).to be_empty
      end
    end

    context "when given a regex" do
      it "does not simplify strings" do
        expect(subject.search(/with\-dashes/)).to eq ["with-dashes"]
      end
    end

    context "when given a string" do
      it "simplifies both the query and searched strings" do
        expect(subject.search("with dashes")).to eq ["with-dashes"]
      end
    end
  end
end
