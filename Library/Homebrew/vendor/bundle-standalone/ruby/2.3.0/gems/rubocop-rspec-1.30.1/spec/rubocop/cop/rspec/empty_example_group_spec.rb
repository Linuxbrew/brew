# frozen_string_literal: true

RSpec.describe RuboCop::Cop::RSpec::EmptyExampleGroup, :config do
  subject(:cop) { described_class.new(config) }

  it 'flags an empty context' do
    expect_offense(<<-RUBY)
      describe Foo do
        context 'when bar' do
        ^^^^^^^^^^^^^^^^^^ Empty example group detected.

          let(:foo) { bar }
        end

        describe '#thingy?' do
          specify do
            expect(whatever.thingy?).to be(true)
          end
        end

        it { should be_true }
      end
    RUBY
  end

  it 'flags an empty top level describe' do
    expect_offense(<<-RUBY)
      describe Foo do
      ^^^^^^^^^^^^ Empty example group detected.
      end
    RUBY
  end

  it 'does not flag include_examples' do
    expect_no_offenses(<<-RUBY)
      describe Foo do
        context "when something is true" do
          include_examples "some expectations"
        end

        context "when something else is true" do
          include_context "some expectations"
        end

        context "when a third thing is true" do
          it_behaves_like "some thingy"
        end
      end
    RUBY
  end

  it 'does not flag methods matching example group names' do
    expect_no_offenses(<<-RUBY)
      describe Foo do
        it 'yields a block when given' do
          value = nil

          helper.feature('whatevs') { value = 5 }

          expect(value).to be 5
        end
      end
    RUBY
  end

  it 'does not recognize custom include methods by default' do
    expect_offense(<<-RUBY)
      describe Foo do
      ^^^^^^^^^^^^ Empty example group detected.
        context "when I do something clever" do
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Empty example group detected.
          it_has_special_behavior
        end
      end
    RUBY
  end

  context 'when a custom include method is specified' do
    let(:cop_config) do
      { 'CustomIncludeMethods' => %w[it_has_special_behavior] }
    end

    it 'does not flag an otherwise empty example group' do
      expect_no_offenses(<<-RUBY)
        describe Foo do
          context "when I do something clever" do
            it_has_special_behavior
          end
        end
      RUBY
    end
  end
end
