# frozen_string_literal: true

RSpec.describe RuboCop::Cop::RSpec::LetSetup do
  subject(:cop) { described_class.new }

  it 'complains when let! is used and not referenced' do
    expect_offense(<<-RUBY)
      describe Foo do
        let!(:foo) { bar }
        ^^^^^^^^^^ Do not use `let!` for test setup.

        it 'does not use foo' do
          expect(baz).to eq(qux)
        end
      end
    RUBY
  end

  it 'ignores let! when used in `before`' do
    expect_no_offenses(<<-RUBY)
      describe Foo do
        let!(:foo) { bar }

        before do
          foo
        end

        it 'does not use foo' do
          expect(baz).to eq(qux)
        end
      end
    RUBY
  end

  it 'ignores let! when used in example' do
    expect_no_offenses(<<-RUBY)
      describe Foo do
        let!(:foo) { bar }

        it 'uses foo' do
          foo
          expect(baz).to eq(qux)
        end
      end
    RUBY
  end

  it 'complains when let! is used and not referenced within nested group' do
    expect_offense(<<-RUBY)
      describe Foo do
        context 'when something special happens' do
          let!(:foo) { bar }
          ^^^^^^^^^^ Do not use `let!` for test setup.

          it 'does not use foo' do
            expect(baz).to eq(qux)
          end
        end

        it 'references some other foo' do
          foo
        end
      end
    RUBY
  end
end
