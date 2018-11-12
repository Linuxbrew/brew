RSpec.describe RuboCop::Cop::RSpec::Capybara::FeatureMethods, :config do
  subject(:cop) { described_class.new(config) }

  let(:cop_config) { { 'EnabledMethods' => [] } }

  it 'flags violations for `background`' do
    expect_offense(<<-RUBY)
      describe 'some feature' do
        background do; end
        ^^^^^^^^^^ Use `before` instead of `background`.
      end
    RUBY
  end

  it 'flags violations for `scenario`' do
    expect_offense(<<-RUBY)
      RSpec.describe 'some feature' do
        scenario 'Foo' do; end
        ^^^^^^^^ Use `it` instead of `scenario`.
      end
    RUBY
  end

  it 'flags violations for `xscenario`' do
    expect_offense(<<-RUBY)
      describe 'Foo' do
        RSpec.xscenario 'Baz' do; end
              ^^^^^^^^^ Use `xit` instead of `xscenario`.
      end
    RUBY
  end

  it 'flags violations for `given`' do
    expect_offense(<<-RUBY)
      RSpec.describe 'Foo' do
        given(:foo) { :foo }
        ^^^^^ Use `let` instead of `given`.
      end
    RUBY
  end

  it 'flags violations for `given!`' do
    expect_offense(<<-RUBY)
      describe 'Foo' do
        given!(:foo) { :foo }
        ^^^^^^ Use `let!` instead of `given!`.
      end
    RUBY
  end

  it 'flags violations for `feature`' do
    expect_offense(<<-RUBY)
      RSpec.feature 'Foo' do; end
            ^^^^^^^ Use `describe` instead of `feature`.
    RUBY
  end

  it 'ignores variables inside examples' do
    expect_no_offenses(<<-RUBY)
      it 'is valid code' do
        given(feature)
        assign(background)
        run scenario
      end
    RUBY
  end

  it 'ignores feature calls outside spec' do
    expect_no_offenses(<<-RUBY)
      FactoryBot.define do
        factory :company do
          feature { "a company" }
          background { Faker::Lorem.sentence }
        end
      end
    RUBY
  end

  it 'allows includes before the spec' do
    expect_offense(<<-RUBY)
      require 'rails_helper'

      RSpec.feature 'Foo' do; end
            ^^^^^^^ Use `describe` instead of `feature`.
    RUBY
  end

  context 'with configured `EnabledMethods`' do
    let(:cop_config) { { 'EnabledMethods' => %w[feature] } }

    it 'ignores usage of the enabled method' do
      expect_no_offenses(<<-RUBY)
        RSpec.feature 'feature is enabled' do; end
      RUBY
    end

    it 'flags other methods' do
      expect_offense(<<-RUBY)
        RSpec.feature 'feature is enabled' do
          given(:foo) { :foo }
          ^^^^^ Use `let` instead of `given`.
        end
      RUBY
    end
  end

  shared_examples 'autocorrect_spec' do |original, corrected|
    original = <<-RUBY
      describe Foo do
        #{original}
      end
    RUBY
    corrected = <<-RUBY
      describe Foo do
        #{corrected}
      end
    RUBY

    include_examples 'autocorrect', original, corrected
  end

  include_examples 'autocorrect_spec', 'background { }',    'before { }'
  include_examples 'autocorrect_spec', 'scenario { }',      'it { }'
  include_examples 'autocorrect_spec', 'xscenario { }',     'xit { }'
  include_examples 'autocorrect_spec', 'given(:foo) { }',   'let(:foo) { }'
  include_examples 'autocorrect_spec', 'given!(:foo) { }',  'let!(:foo) { }'
  include_examples 'autocorrect_spec', 'RSpec.feature { }', 'RSpec.describe { }'
end
