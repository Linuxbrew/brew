# frozen_string_literal: true

RSpec.describe RuboCop::Cop::RSpec::ExpectInHook do
  subject(:cop) { described_class.new }

  it 'adds an offense for `expect` in `before` hook' do
    expect_offense(<<-RUBY)
      before do
        expect(something).to eq('foo')
        ^^^^^^ Do not use `expect` in `before` hook
        is_expected.to eq('foo')
        ^^^^^^^^^^^ Do not use `is_expected` in `before` hook
        expect_any_instance_of(Something).to receive(:foo)
        ^^^^^^^^^^^^^^^^^^^^^^ Do not use `expect_any_instance_of` in `before` hook
      end
    RUBY
  end

  it 'adds an offense for `expect` in `after` hook' do
    expect_offense(<<-RUBY)
      after do
        expect(something).to eq('foo')
        ^^^^^^ Do not use `expect` in `after` hook
        is_expected.to eq('foo')
        ^^^^^^^^^^^ Do not use `is_expected` in `after` hook
        expect_any_instance_of(Something).to receive(:foo)
        ^^^^^^^^^^^^^^^^^^^^^^ Do not use `expect_any_instance_of` in `after` hook
      end
    RUBY
  end

  it 'adds an offense for `expect` in `around` hook' do
    expect_offense(<<-RUBY)
      around do
        expect(something).to eq('foo')
        ^^^^^^ Do not use `expect` in `around` hook
        is_expected(something).to eq('foo')
        ^^^^^^^^^^^ Do not use `is_expected` in `around` hook
        expect_any_instance_of(Something).to receive(:foo)
        ^^^^^^^^^^^^^^^^^^^^^^ Do not use `expect_any_instance_of` in `around` hook
      end
    RUBY
  end

  it 'adds an offense for `expect` with block in `before` hook' do
    expect_offense(<<-RUBY)
      before do
        expect { something }.to eq('foo')
        ^^^^^^ Do not use `expect` in `before` hook
      end
    RUBY
  end

  it 'accepts an empty `before` hook' do
    expect_no_offenses(<<-RUBY)
      before do
      end
    RUBY
  end

  it 'accepts `allow` in `before` hook' do
    expect_no_offenses(<<-RUBY)
      before do
        allow(something).to receive(:foo)
        allow_any_instance_of(something).to receive(:foo)
      end
    RUBY
  end

  it 'accepts `expect` in `it`' do
    expect_no_offenses(<<-RUBY)
      it do
        expect(something).to eq('foo')
        is_expected.to eq('foo')
        expect_any_instance_of(something).to receive(:foo)
      end
    RUBY
  end
end
