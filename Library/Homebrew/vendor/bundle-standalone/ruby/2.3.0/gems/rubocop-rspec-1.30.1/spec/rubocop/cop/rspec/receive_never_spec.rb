# frozen_string_literal: true

RSpec.describe RuboCop::Cop::RSpec::ReceiveNever do
  subject(:cop) { described_class.new }

  it 'flags usage of `never`' do
    expect_offense(<<-RUBY)
      expect(foo).to receive(:bar).never
                                   ^^^^^ Use `not_to receive` instead of `never`.
    RUBY
  end

  it 'flags usage of `never` after `with`' do
    expect_offense(<<-RUBY)
      expect(foo).to receive(:bar).with(baz).never
                                             ^^^^^ Use `not_to receive` instead of `never`.
    RUBY
  end

  it 'flags usage of `never` with `is_expected`' do
    expect_offense(<<-RUBY)
      is_expected.to receive(:bar).with(baz).never
                                             ^^^^^ Use `not_to receive` instead of `never`.
    RUBY
  end

  it 'flags usage of `never` with `expect_any_instance_of`' do
    expect_offense(<<-RUBY)
      expect_any_instance_of(Foo).to receive(:bar).with(baz).never
                                                             ^^^^^ Use `not_to receive` instead of `never`.
    RUBY
  end

  it 'allows method called `never`' do
    expect_no_offenses(<<-RUBY)
      expect(foo).to receive(:bar).with(Value.never)
      expect(foo.never).to eq(bar.never)
      is_expected.to be never
    RUBY
  end

  include_examples 'autocorrect',
                   'expect(foo).to receive(:bar).with(0).never',
                   'expect(foo).not_to receive(:bar).with(0)'
end
