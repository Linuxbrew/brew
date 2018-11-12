RSpec.describe RuboCop::Cop::RSpec::Be do
  subject(:cop) { described_class.new }

  it 'registers an offense for `be` without an argument' do
    expect_offense(<<-RUBY)
      it { expect(foo).to be }
                          ^^ Don't use `be` without an argument.
    RUBY
  end

  it 'registers an offense for not_to be' do
    expect_offense(<<-RUBY)
      it { expect(foo).not_to be }
                              ^^ Don't use `be` without an argument.
      it { expect(foo).to_not be }
                              ^^ Don't use `be` without an argument.
    RUBY
  end

  it 'allows `be` with an argument' do
    expect_no_offenses(<<-RUBY)
      it { expect(foo).to be(1) }
      it { expect(foo).not_to be(0) }
    RUBY
  end

  it 'allows specific `be_` matchers' do
    expect_no_offenses(<<-RUBY)
      it { expect(foo).to be_truthy }
      it { expect(foo).not_to be_falsy }
    RUBY
  end
end
