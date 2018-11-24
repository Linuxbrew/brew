# frozen_string_literal: true

RSpec.describe RuboCop::Cop::RSpec::EmptyLineAfterHook do
  subject(:cop) { described_class.new }

  it 'checks for empty line after `before` hook' do
    expect_offense(<<-RUBY)
      RSpec.describe User do
        before { do_something }
        ^^^^^^^^^^^^^^^^^^^^^^^ Add an empty line after `before`.
        it { does_something }
      end
    RUBY
  end

  it 'checks for empty line after `after` hook' do
    expect_offense(<<-RUBY)
      RSpec.describe User do
        after { do_something }
        ^^^^^^^^^^^^^^^^^^^^^^ Add an empty line after `after`.
        it { does_something }
      end
    RUBY
  end

  it 'checks for empty line after `around` hook' do
    expect_offense(<<-RUBY)
      RSpec.describe User do
        around { |test| test.run }
        ^^^^^^^^^^^^^^^^^^^^^^^^^^ Add an empty line after `around`.
        it { does_something }
      end
    RUBY
  end

  it 'approves empty line after `before` hook' do
    expect_no_offenses(<<-RUBY)
      RSpec.describe User do
        before { do_something }

        it { does_something }
      end
    RUBY
  end

  it 'approves empty line after `after` hook' do
    expect_no_offenses(<<-RUBY)
      RSpec.describe User do
        after { do_something }

        it { does_something }
      end
    RUBY
  end

  it 'approves empty line after `around` hook' do
    expect_no_offenses(<<-RUBY)
      RSpec.describe User do
        around { |test| test.run }

        it { does_something }
      end
    RUBY
  end

  it 'handles multiline `before` block' do
    expect_no_offenses(<<-RUBY)
      RSpec.describe User do
        before do
          do_something
        end

        it { does_something }
      end
    RUBY
  end

  it 'handles multiline `after` block' do
    expect_no_offenses(<<-RUBY)
      RSpec.describe User do
        after do
          do_something
        end

        it { does_something }
      end
    RUBY
  end

  it 'handles multiline `around` block' do
    expect_no_offenses(<<-RUBY)
      RSpec.describe User do
        around do |test|
          test.run
        end

        it { does_something }
      end
    RUBY
  end

  it 'handles `before` being the latest node' do
    expect_no_offenses(<<-RUBY)
      RSpec.describe User do
        before { do_something }
      end
    RUBY
  end

  bad_example = <<-RUBY
    RSpec.describe User do
      before { do_something }
      it { does_something }
    end
  RUBY

  good_example = <<-RUBY
    RSpec.describe User do
      before { do_something }

      it { does_something }
    end
  RUBY

  include_examples 'autocorrect',
                   bad_example,
                   good_example
end
