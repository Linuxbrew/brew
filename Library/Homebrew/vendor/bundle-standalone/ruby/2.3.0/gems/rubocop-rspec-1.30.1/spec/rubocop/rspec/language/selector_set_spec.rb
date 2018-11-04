RSpec.describe RuboCop::RSpec::Language::SelectorSet do
  subject(:selector_set) { described_class.new(%i[foo bar]) }

  it 'composes sets' do
    combined = selector_set + described_class.new(%i[baz])

    expect(combined).to eq(described_class.new(%i[foo bar baz]))
  end

  it 'compares by value' do
    expect(selector_set).not_to eq(described_class.new(%i[foo bar baz]))
  end

  describe '#include?' do
    it 'returns false for selectors not in the set' do
      expect(selector_set.include?(:baz)).to be(false)
    end

    it 'returns true for selectors in the set' do
      expect(selector_set.include?(:foo)).to be(true)
    end
  end

  describe '#node_pattern' do
    it 'builds a node pattern' do
      expect(selector_set.node_pattern).to eql(':foo :bar')
    end
  end

  describe '#node_pattern_union' do
    it 'builds a node pattern union' do
      expect(selector_set.node_pattern_union).to eql('{:foo :bar}')
    end
  end

  describe '#send_pattern' do
    it 'builds a send matching pattern' do
      expect(selector_set.send_pattern).to eql(
        '(send {(const nil? :RSpec) nil?} {:foo :bar} ...)'
      )
    end
  end

  describe '#block_pattern' do
    it 'builds a block matching pattern' do
      expect(selector_set.block_pattern).to eql(
        '(block (send {(const nil? :RSpec) nil?} {:foo :bar} ...) ...)'
      )
    end
  end
end
