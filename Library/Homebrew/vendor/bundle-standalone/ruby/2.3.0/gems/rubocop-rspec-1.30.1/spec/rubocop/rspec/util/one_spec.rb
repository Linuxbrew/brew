RSpec.describe RuboCop::RSpec::Util, '.one' do
  let(:first)  { instance_double(Object)                          }
  let(:array)  { instance_double(Array, one?: true, first: first) }
  let(:client) { Class.new.extend(described_class)                }

  it 'returns first element' do
    expect(client.one(array)).to be(first)
  end

  it 'fails if the list is empty' do
    expect { client.one([]) }
      .to raise_error(described_class::SizeError)
      .with_message('expected size to be exactly 1 but size was 0')
  end

  it 'fails if the list has more than one element' do
    expect { client.one([1, 2]) }
      .to raise_error(described_class::SizeError)
      .with_message('expected size to be exactly 1 but size was 2')
  end
end
