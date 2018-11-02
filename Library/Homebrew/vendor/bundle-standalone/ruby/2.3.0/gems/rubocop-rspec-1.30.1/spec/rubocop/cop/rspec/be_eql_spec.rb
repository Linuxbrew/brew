RSpec.describe RuboCop::Cop::RSpec::BeEql do
  subject(:cop) { described_class.new }

  it 'registers an offense for `eql` when argument is a boolean' do
    expect_offense(<<-RUBY)
      it { expect(foo).to eql(true) }
                          ^^^ Prefer `be` over `eql`.
      it { expect(foo).to eql(false) }
                          ^^^ Prefer `be` over `eql`.
    RUBY
  end

  it 'registers an offense for `eql` when argument is an integer' do
    expect_offense(<<-RUBY)
      it { expect(foo).to eql(0) }
                          ^^^ Prefer `be` over `eql`.
      it { expect(foo).to eql(123) }
                          ^^^ Prefer `be` over `eql`.
    RUBY
  end

  it 'registers an offense for `eql` when argument is a float' do
    expect_offense(<<-RUBY)
      it { expect(foo).to eql(1.0) }
                          ^^^ Prefer `be` over `eql`.
      it { expect(foo).to eql(1.23) }
                          ^^^ Prefer `be` over `eql`.
    RUBY
  end

  it 'registers an offense for `eql` when argument is a symbol' do
    expect_offense(<<-RUBY)
      it { expect(foo).to eql(:foo) }
                          ^^^ Prefer `be` over `eql`.
    RUBY
  end

  it 'registers an offense for `eql` when argument is nil' do
    expect_offense(<<-RUBY)
      it { expect(foo).to eql(nil) }
                          ^^^ Prefer `be` over `eql`.
    RUBY
  end

  it 'does not register an offense for `eql` when argument is a string' do
    expect_no_offenses(<<-RUBY)
      it { expect(foo).to eql('foo') }
    RUBY
  end

  it 'does not register an offense for `eql` when expectation is negated' do
    expect_no_offenses(<<-RUBY)
      it { expect(foo).to_not eql(1) }
    RUBY
  end

  include_examples 'autocorrect',
                   'it { expect(foo).to eql(1) }',
                   'it { expect(foo).to be(1) }'
end
