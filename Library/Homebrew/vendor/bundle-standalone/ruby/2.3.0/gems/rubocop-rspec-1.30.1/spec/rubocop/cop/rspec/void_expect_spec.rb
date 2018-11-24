RSpec.describe RuboCop::Cop::RSpec::VoidExpect do
  subject(:cop) { described_class.new }

  it 'registers offenses to void `expect`' do
    expect_offense(<<-RUBY)
      it 'something' do
        something = 1
        expect(something)
        ^^^^^^^^^^^^^^^^^ Do not use `expect()` without `.to` or `.not_to`. Chain the methods or remove it.
      end
    RUBY
  end

  it 'registers offenses to void `expect` when block has one expression' do
    expect_offense(<<-RUBY)
      it 'something' do
        expect(something)
        ^^^^^^^^^^^^^^^^^ Do not use `expect()` without `.to` or `.not_to`. Chain the methods or remove it.
      end
    RUBY
  end

  it 'registers offenses to void `expect` with block' do
    expect_offense(<<-RUBY)
      it 'something' do
        expect{something}
        ^^^^^^^^^^^^^^^^^ Do not use `expect()` without `.to` or `.not_to`. Chain the methods or remove it.
      end
    RUBY
  end

  it 'accepts non-void `expect`' do
    expect_no_offenses(<<-RUBY)
      it 'something' do
        expect(something).to be 1
      end
    RUBY
  end

  it 'accepts non-void `expect` with block' do
    expect_no_offenses(<<-RUBY)
      it 'something' do
        expect{something}.to raise_error(StandardError)
      end
    RUBY
  end
end
