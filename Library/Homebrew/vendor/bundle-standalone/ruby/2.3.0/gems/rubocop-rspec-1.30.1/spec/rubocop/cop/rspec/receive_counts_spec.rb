# frozen_string_literal: true

RSpec.describe RuboCop::Cop::RSpec::ReceiveCounts do
  subject(:cop) { described_class.new }

  it 'flags usage of `exactly(1).times`' do
    expect_offense(<<-RUBY)
      expect(foo).to receive(:bar).exactly(1).times
                                  ^^^^^^^^^^^^^^^^^ Use `.once` instead of `.exactly(1).times`.
    RUBY
  end

  it 'flags usage of `exactly(2).times`' do
    expect_offense(<<-RUBY)
      expect(foo).to receive(:bar).exactly(2).times
                                  ^^^^^^^^^^^^^^^^^ Use `.twice` instead of `.exactly(2).times`.
    RUBY
  end

  it 'allows `exactly(3).times`' do
    expect_no_offenses(<<-RUBY)
      expect(foo).to receive(:bar).exactly(3).times
    RUBY
  end

  it 'allows `exactly(n).times`' do
    expect_no_offenses(<<-RUBY)
      expect(foo).to receive(:bar).exactly(n).times
    RUBY
  end

  it 'flags usage of `exactly(1).times` after `with`' do
    expect_offense(<<-RUBY)
      expect(foo).to receive(:bar).with(baz).exactly(1).times
                                            ^^^^^^^^^^^^^^^^^ Use `.once` instead of `.exactly(1).times`.
    RUBY
  end

  it 'flags usage of `exactly(1).times` with return value' do
    expect_offense(<<-RUBY)
      expect(foo).to receive(:bar).exactly(1).times.and_return(true)
                                  ^^^^^^^^^^^^^^^^^ Use `.once` instead of `.exactly(1).times`.
    RUBY
  end

  it 'flags usage of `exactly(1).times` with a block' do
    expect_offense(<<-RUBY)
      expect(foo).to receive(:bar).exactly(1).times { true }
                                  ^^^^^^^^^^^^^^^^^ Use `.once` instead of `.exactly(1).times`.
    RUBY
  end

  it 'flags usage of `at_least(1).times`' do
    expect_offense(<<-RUBY)
      expect(foo).to receive(:bar).at_least(1).times
                                  ^^^^^^^^^^^^^^^^^^ Use `.at_least(:once)` instead of `.at_least(1).times`.
    RUBY
  end

  it 'flags usage of `at_least(2).times`' do
    expect_offense(<<-RUBY)
      expect(foo).to receive(:bar).at_least(2).times
                                  ^^^^^^^^^^^^^^^^^^ Use `.at_least(:twice)` instead of `.at_least(2).times`.
    RUBY
  end

  it 'flags usage of `at_most(1).times`' do
    expect_offense(<<-RUBY)
      expect(foo).to receive(:bar).at_most(1).times
                                  ^^^^^^^^^^^^^^^^^ Use `.at_most(:once)` instead of `.at_most(1).times`.
    RUBY
  end

  it 'flags usage of `at_most(2).times`' do
    expect_offense(<<-RUBY)
      expect(foo).to receive(:bar).at_most(2).times
                                  ^^^^^^^^^^^^^^^^^ Use `.at_most(:twice)` instead of `.at_most(2).times`.
    RUBY
  end

  include_examples 'autocorrect',
                   'expect(foo).to receive(:bar).exactly(1).times { true }',
                   'expect(foo).to receive(:bar).once { true }'

  include_examples 'autocorrect',
                   'expect(foo).to receive(:bar).at_least(2).times { true }',
                   'expect(foo).to receive(:bar).at_least(:twice) { true }'
end
