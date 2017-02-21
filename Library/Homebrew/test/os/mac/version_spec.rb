require "version"
require "os/mac/version"

describe OS::Mac::Version do
  subject { described_class.new("10.7") }

  specify "comparison with Symbol" do
    expect(subject).to be > :snow_leopard
    expect(subject).to be == :lion
    expect(subject).to be === :lion # rubocop:disable Style/CaseEquality
    expect(subject).to be < :mountain_lion
  end

  specify "comparison with Fixnum" do
    expect(subject).to be > 10
    expect(subject).to be < 11
  end

  specify "comparison with Float" do
    expect(subject).to be > 10.6
    expect(subject).to be == 10.7
    expect(subject).to be === 10.7 # rubocop:disable Style/CaseEquality
    expect(subject).to be < 10.8
  end

  specify "comparison with String" do
    expect(subject).to be > "10.6"
    expect(subject).to be == "10.7"
    expect(subject).to be === "10.7" # rubocop:disable Style/CaseEquality
    expect(subject).to be < "10.8"
  end

  specify "comparison with Version" do
    expect(subject).to be > Version.create("10.6")
    expect(subject).to be == Version.create("10.7")
    expect(subject).to be === Version.create("10.7") # rubocop:disable Style/CaseEquality
    expect(subject).to be < Version.create("10.8")
  end

  specify "#from_symbol" do
    expect(described_class.from_symbol(:lion)).to eq(subject)
    expect { described_class.from_symbol(:foo) }
      .to raise_error(ArgumentError)
  end

  specify "#pretty_name" do
    expect(described_class.new("10.11").pretty_name).to eq("El Capitan")
    expect(described_class.new("10.8").pretty_name).to eq("Mountain Lion")
    expect(described_class.new("10.10").pretty_name).to eq("Yosemite")
  end
end
