RSpec.describe RuboCop::Cop::RSpec::InvalidPredicateMatcher do
  subject(:cop) { described_class.new }

  it 'registers an offense for double question' do
    expect_offense(<<-RUBY)
      expect(foo).to be_something?
                     ^^^^^^^^^^^^^ Omit `?` from `be_something?`.
    RUBY
  end

  it 'registers an offense for double question with `not_to`' do
    expect_offense(<<-RUBY)
      expect(foo).not_to be_something?
                         ^^^^^^^^^^^^^ Omit `?` from `be_something?`.
    RUBY
  end

  it 'registers an offense for double question with `to_not`' do
    expect_offense(<<-RUBY)
      expect(foo).to_not be_something?
                         ^^^^^^^^^^^^^ Omit `?` from `be_something?`.
    RUBY
  end

  it 'registers an offense for double question with `have_something?`' do
    expect_offense(<<-RUBY)
      expect(foo).to have_something?
                     ^^^^^^^^^^^^^^^ Omit `?` from `have_something?`.
    RUBY
  end

  it 'accepts valid predicate matcher' do
    expect_no_offenses(<<-RUBY)
      expect(foo).to be_something
    RUBY
  end
end
