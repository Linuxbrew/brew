RSpec.describe 'Weirdness' do
  subject! { nil }
  subject { nil }
  subject(:foo) { nil }
  subject!(:foo) { nil }

  subject! (:foo) { |something| nil }
  subject  :foo  do end

  let(:foo) { |something| something }
  let (:foo) { 1 }
  let!   (:bar){}

  let :a do end

  let(:bar) { <<-HEREDOC }
    What a pain.
  HEREDOC

  let(:bar) { <<-'HEREDOC' }
    Even odder.
  HEREDOC

  let(:baz) do
    <<-INSIDE
      Hi. I'm in your lets.
    INSIDE
  end

  let(:hi)      {}
  let(:bye) do
  end

  let(:doop) { foo; 1 }

  it {}
  specify {}

  it 'works', metadata: true do
  end

  describe {}
  context {}

  describe '#nothing' do
  end

  it 'is empty' do
  end

  it '' do end
  describe do end
  context do end
  shared_examples 'a' do end

  describe 'things' do
    context 'with context' do
    end
  end

  shared_examples 'weird rspec' do
  end

  shared_examples :something do
  end

  context 'test' do
    include_examples 'weird rspec'
    include_examples('weird rspec', serious: true) do
      it_behaves_like :something
    end
  end

  it_behaves_like :something
  it_should_behave_like :something

  it_behaves_like :something do
    let(:foo) { 'bar' }
  end

  it_behaves_like(:something) do |arg, *args, &block|
  end

  before {}
  context 'never run' do
    around {}
  end
  after {}

  before { <<-DOC }
   Eh, what's up?
  DOC

  around { |test| test.run; <<-DOC }
   Eh, what's up?
  DOC

  after { <<-DOC }
   Eh, what's up?
  DOC

  around do |test|
    test.run
  end

  it 'is expecting you' do
    expect('you').to eql('you')
  end

  it 'is expecting you not to raise an error' do
    expect { 'you' }.not_to raise_error
  end

  it 'has chained expectations' do
    expect('you').to eql('you').and(match(/y/))
  end

  %w[who likes dynamic examples].each do |word|
    let(word) { word }

    describe "#{word}" do
      context "#{word}" do
        it "lets the word '#{word}' be '#{word}'" do
          expect(send(word)).to eql(word)
        end
      end
    end
  end

  it { foo; 1 && 2}
  it('has a description too') { foo; 1 && 2}

  it %{quotes a string weird} do
  end

  it((' '.strip! ; 1 && 'isnt a simple string')) do
    expect(nil).to be(nil)
  end

  it((' '.strip! ; 1 && 'isnt a simple string')) do
    double = double(:foo)

    allow(double).to receive(:oogabooga).with(nil).and_return(nil)

    expect(double.oogabooga(nil)).to be(nil)

    expect(double).to have_received(:oogabooga).once
  end

  it 'uses a matcher' do
    expect([].empty?).to be(true)
    expect([]).to be_empty
  end

  let(:klass) do
    Class.new do
      def initialize(thing)
        @thing = thing
      end

      def announce
        'wooo, so dynamic!'
      end
    end
  end

  it 'it does a thing' do
  end

  it 'It does a thing' do
  end

  it 'should not do the thing' do
  end

  specify do
    foo = double(:bar)
    allow(foo).to receive_message_chain(bar: 42, baz: 42)
    allow(foo).to receive(:bar)
    allow(foo).to receive_messages(bar: 42, baz: 42)
  end
end

RSpec.describe {}
RSpec.shared_examples('pointless') {}
RSpec.shared_context('even pointless-er') {}
RSpec.describe do end
RSpec.shared_examples('pointless2') do end
RSpec.shared_context('even pointless-er2') do end

class Broken
end

RSpec.describe Broken do
end

RSpec.describe 'RubocopBug' do
  subject { true }

  before do
    each_row = allow(double(:exporter)).to receive(:each_row)

    [1, 2].each do |sig|
      each_row = each_row.and_yield(sig)
    end
  end

  it 'has a single example' do
    expect(subject).to be_truthy
  end

  it 'has an expectation' do
    stats = double(event: nil)

    stats.event('tada!')

    expect(stats)
      .to have_received(:event)
      .with('tada!')
  end
end

RSpec.describe do
  let(:uh_oh) { <<-HERE.strip + ", #{<<-THERE.strip}" }
      Seriously
  HERE
      who designed these things?
  THERE

  it 'is insane' do
    expect(uh_oh).to eql('Seriously, who designed these things?')
  end
end
