# frozen_string_literal: true

RSpec.describe RuboCop::Cop::RSpec::MultipleExpectations, :config do
  subject(:cop) { described_class.new(config) }

  context 'without configuration' do
    let(:cop_config) { {} }

    it 'flags multiple expectations' do
      expect_offense(<<-RUBY)
        describe Foo do
          it 'uses expect twice' do
          ^^^^^^^^^^^^^^^^^^^^^^ Example has too many expectations [2/1].
            expect(foo).to eq(bar)
            expect(baz).to eq(bar)
          end
        end
      RUBY
    end

    it 'approves of one expectation per example' do
      expect_no_offenses(<<-RUBY)
        describe Foo do
          it 'does something neat' do
            expect(neat).to be(true)
          end

          it 'does something cool' do
            expect(cool).to be(true)
          end
        end
      RUBY
    end

    it 'flags multiple expect_any_instance_of' do
      expect_offense(<<-RUBY)
        describe Foo do
          it 'uses expect_any_instance_of twice' do
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Example has too many expectations [2/1].
            expect_any_instance_of(Foo).to receive(:bar)
            expect_any_instance_of(Foo).to receive(:baz)
          end
        end
      RUBY
    end

    it 'flags multiple is_expected' do
      expect_offense(<<-RUBY)
        describe Foo do
          it 'uses expect_any_instance_of twice' do
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Example has too many expectations [2/1].
            is_expected.to receive(:bar)
            is_expected.to receive(:baz)
          end
        end
      RUBY
    end

    it 'flags multiple expects with blocks' do
      expect_offense(<<-RUBY)
        describe Foo do
          it 'uses expect with block twice' do
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Example has too many expectations [2/1].
            expect { something }.to change(Foo.count)
            expect { something }.to change(Bar.count)
          end
        end
      RUBY
    end

    it 'counts aggregate_failures as one expectation' do
      expect_no_offenses(<<-RUBY)
        describe Foo do
          it 'aggregates failures' do
            aggregate_failures do
              expect(foo).to eq(bar)
              expect(baz).to eq(bar)
            end
          end
        end
      RUBY
    end

    it 'counts every aggregate_failures as an expectation' do
      expect_offense(<<-RUBY)
        describe Foo do
          it 'has multiple aggregate_failures calls' do
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Example has too many expectations [2/1].
            aggregate_failures do
            end
            aggregate_failures do
            end
          end
        end
      RUBY
    end
  end

  context 'with meta data' do
    it 'ignores examples with `:aggregate_failures`' do
      expect_no_offenses(<<-RUBY)
        describe Foo do
          it 'uses expect twice', :aggregate_failures do
            expect(foo).to eq(bar)
            expect(baz).to eq(bar)
          end
        end
      RUBY
    end

    it 'ignores examples with `aggregate_failures: true`' do
      expect_no_offenses(<<-RUBY)
        describe Foo do
          it 'uses expect twice', aggregate_failures: true do
            expect(foo).to eq(bar)
            expect(baz).to eq(bar)
          end
        end
      RUBY
    end

    it 'checks examples with `aggregate_failures: false`' do
      expect_offense(<<-RUBY)
        describe Foo do
          it 'uses expect twice', aggregate_failures: false do
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Example has too many expectations [2/1].
            expect(foo).to eq(bar)
            expect(baz).to eq(bar)
          end
        end
      RUBY
    end
  end

  context 'with Max configuration' do
    let(:cop_config) do
      { 'Max' => '2' }
    end

    it 'permits two expectations' do
      expect_no_offenses(<<-RUBY)
        describe Foo do
          it 'uses expect twice' do
            expect(foo).to eq(bar)
            expect(baz).to eq(bar)
          end
        end
      RUBY
    end

    it 'flags three expectations' do
      expect_offense(<<-RUBY)
        describe Foo do
          it 'uses expect three times' do
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Example has too many expectations [3/2].
            expect(foo).to eq(bar)
            expect(baz).to eq(bar)
            expect(qux).to eq(bar)
          end
        end
      RUBY
    end
  end

  context 'with AggregateFailuresByDefault configuration' do
    let(:cop_config) do
      { 'AggregateFailuresByDefault' => true }
    end

    it 'ignores examples without metadata' do
      expect_no_offenses(<<-RUBY)
        describe Foo do
          it 'uses expect twice' do
            expect(foo).to eq(bar)
            expect(baz).to eq(bar)
          end
        end
      RUBY
    end

    it 'ignores examples with `:aggregate_failures`' do
      expect_no_offenses(<<-RUBY)
        describe Foo do
          it 'uses expect twice', :aggregate_failures do
            expect(foo).to eq(bar)
            expect(baz).to eq(bar)
          end
        end
      RUBY
    end

    it 'ignores examples with `aggregate_failures: true`' do
      expect_no_offenses(<<-RUBY)
        describe Foo do
          it 'uses expect twice', aggregate_failures: true do
            expect(foo).to eq(bar)
            expect(baz).to eq(bar)
          end
        end
      RUBY
    end

    it 'checks examples with `aggregate_failures: false`' do
      expect_offense(<<-RUBY)
        describe Foo do
          it 'uses expect twice', aggregate_failures: false do
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Example has too many expectations [2/1].
            expect(foo).to eq(bar)
            expect(baz).to eq(bar)
          end
        end
      RUBY
    end
  end

  it 'generates a todo based on the worst violation' do
    inspect_source(<<-RUBY, 'spec/foo_spec.rb')
      describe Foo do
        it 'uses expect twice' do
          expect(foo).to eq(bar)
          expect(baz).to eq(bar)
        end

        it 'uses expect three times' do
          expect(foo).to eq(bar)
          expect(baz).to eq(bar)
          expect(qux).to eq(bar)
        end
      end
    RUBY

    expect(cop.config_to_allow_offenses[:exclude_limit]).to eq('Max' => 3)
  end
end
