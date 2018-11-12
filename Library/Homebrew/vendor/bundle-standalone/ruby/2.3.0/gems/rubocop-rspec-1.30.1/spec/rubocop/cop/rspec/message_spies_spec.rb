# frozen_string_literal: true

RSpec.describe RuboCop::Cop::RSpec::MessageSpies, :config do
  subject(:cop) { described_class.new(config) }

  context 'when EnforcedStyle is have_received' do
    let(:cop_config) do
      { 'EnforcedStyle' => 'have_received' }
    end

    it 'flags expect(send).to receive' do
      expect_offense(<<-RUBY)
        expect(foo).to receive(:bar)
                       ^^^^^^^ Prefer `have_received` for setting message expectations. Setup `foo` as a spy using `allow` or `instance_spy`.
      RUBY
    end

    it 'flags expect(lvar).to receive' do
      expect_offense(<<-RUBY)
        foo = baz
        expect(foo).to receive(:bar)
                       ^^^^^^^ Prefer `have_received` for setting message expectations. Setup `foo` as a spy using `allow` or `instance_spy`.
      RUBY
    end

    it 'flags expect(ivar).to receive' do
      expect_offense(<<-RUBY)
        expect(@foo).to receive(:bar)
                        ^^^^^^^ Prefer `have_received` for setting message expectations. Setup `@foo` as a spy using `allow` or `instance_spy`.
      RUBY
    end

    it 'flags expect(const).to receive' do
      expect_offense(<<-RUBY)
        expect(Foo).to receive(:bar)
                       ^^^^^^^ Prefer `have_received` for setting message expectations. Setup `Foo` as a spy using `allow` or `instance_spy`.
      RUBY
    end

    it 'flags expect(...).not_to receive' do
      expect_offense(<<-RUBY)
        expect(foo).not_to receive(:bar)
                           ^^^^^^^ Prefer `have_received` for setting message expectations. Setup `foo` as a spy using `allow` or `instance_spy`.
      RUBY
    end

    it 'flags expect(...).to_not receive' do
      expect_offense(<<-RUBY)
        expect(foo).to_not receive(:bar)
                           ^^^^^^^ Prefer `have_received` for setting message expectations. Setup `foo` as a spy using `allow` or `instance_spy`.
      RUBY
    end

    it 'flags expect(...).to receive with' do
      expect_offense(<<-RUBY)
        expect(foo).to receive(:bar).with(:baz)
                       ^^^^^^^ Prefer `have_received` for setting message expectations. Setup `foo` as a spy using `allow` or `instance_spy`.
      RUBY
    end

    it 'flags expect(...).to receive at_most' do
      expect_offense(<<-RUBY)
        expect(foo).to receive(:bar).at_most(42).times
                       ^^^^^^^ Prefer `have_received` for setting message expectations. Setup `foo` as a spy using `allow` or `instance_spy`.
      RUBY
    end

    it 'approves of expect(...).to have_received' do
      expect_no_offenses('expect(foo).to have_received(:bar)')
    end

    include_examples 'detects style', 'expect(foo).to receive(:bar)', 'receive'

    include_examples 'detects style',
                     'expect(foo).to have_received(:bar)',
                     'have_received'
  end

  context 'when EnforcedStyle is receive' do
    let(:cop_config) do
      { 'EnforcedStyle' => 'receive' }
    end

    it 'flags expect(send).to have_received' do
      expect_offense(<<-RUBY)
        expect(foo).to have_received(:bar)
                       ^^^^^^^^^^^^^ Prefer `receive` for setting message expectations.
      RUBY
    end

    it 'flags expect(lvar).to have_received' do
      expect_offense(<<-RUBY)
        foo = baz
        expect(foo).to have_received(:bar)
                       ^^^^^^^^^^^^^ Prefer `receive` for setting message expectations.
      RUBY
    end

    it 'flags expect(ivar).to have_received' do
      expect_offense(<<-RUBY)
        expect(@foo).to have_received(:bar)
                        ^^^^^^^^^^^^^ Prefer `receive` for setting message expectations.
      RUBY
    end

    it 'flags expect(const).to have_received' do
      expect_offense(<<-RUBY)
        expect(Foo).to have_received(:bar)
                       ^^^^^^^^^^^^^ Prefer `receive` for setting message expectations.
      RUBY
    end

    it 'flags expect(...).not_to have_received' do
      expect_offense(<<-RUBY)
        expect(foo).not_to have_received(:bar)
                           ^^^^^^^^^^^^^ Prefer `receive` for setting message expectations.
      RUBY
    end

    it 'flags expect(...).to_not have_received' do
      expect_offense(<<-RUBY)
        expect(foo).to_not have_received(:bar)
                           ^^^^^^^^^^^^^ Prefer `receive` for setting message expectations.
      RUBY
    end

    it 'flags expect(...).to have_received with' do
      expect_offense(<<-RUBY)
        expect(foo).to have_received(:bar).with(:baz)
                       ^^^^^^^^^^^^^ Prefer `receive` for setting message expectations.
      RUBY
    end

    it 'flags expect(...).to have_received at_most' do
      expect_offense(<<-RUBY)
        expect(foo).to have_received(:bar).at_most(42).times
                       ^^^^^^^^^^^^^ Prefer `receive` for setting message expectations.
      RUBY
    end

    it 'approves of expect(...).to receive' do
      expect_no_offenses('expect(foo).to receive(:bar)')
    end

    include_examples 'detects style', 'expect(foo).to receive(:bar)', 'receive'

    include_examples 'detects style',
                     'expect(foo).to have_received(:bar)',
                     'have_received'
  end
end
