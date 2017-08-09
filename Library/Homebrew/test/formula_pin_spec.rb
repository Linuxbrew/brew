require "formula_pin"

describe FormulaPin do
  subject { described_class.new(formula) }
  let(:name) { "double" }
  let(:formula) { double(Formula, name: name, rack: HOMEBREW_CELLAR/name) }

  before(:each) do
    formula.rack.mkpath

    allow(formula).to receive(:installed_prefixes) do
      formula.rack.directory? ? formula.rack.subdirs.sort : []
    end

    allow(formula).to receive(:installed_kegs) do
      formula.installed_prefixes.map { |prefix| Keg.new(prefix) }
    end
  end

  it "is not pinnable by default" do
    expect(subject).not_to be_pinnable
  end

  it "is pinnable if the Keg exists" do
    (formula.rack/"0.1").mkpath
    expect(subject).to be_pinnable
  end

  specify "#pin and #unpin" do
    (formula.rack/"0.1").mkpath

    subject.pin
    expect(subject).to be_pinned
    expect(HOMEBREW_PINNED_KEGS/name).to be_a_directory
    expect(HOMEBREW_PINNED_KEGS.children.count).to eq(1)

    subject.unpin
    expect(subject).not_to be_pinned
    expect(HOMEBREW_PINNED_KEGS).not_to be_a_directory
  end
end
