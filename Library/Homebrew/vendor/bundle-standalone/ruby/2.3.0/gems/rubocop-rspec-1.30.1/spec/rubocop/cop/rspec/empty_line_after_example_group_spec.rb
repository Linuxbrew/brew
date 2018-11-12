# frozen_string_literal: true

RSpec.describe RuboCop::Cop::RSpec::EmptyLineAfterExampleGroup do
  subject(:cop) { described_class.new }

  it 'checks for empty line after describe' do
    expect_offense(<<-RUBY)
      RSpec.describe Foo do
        describe '#bar' do
        end
        ^^^ Add an empty line after `describe`.
        describe '#baz' do
        end
      end
    RUBY
  end

  it 'highlights single line formulations correctly' do
    expect_offense(<<-RUBY)
      RSpec.describe Foo do
        describe('#bar') { }
        ^^^^^^^^^^^^^^^^^^^^ Add an empty line after `describe`.
        describe '#baz' do
        end
      end
    RUBY
  end

  it 'checks for empty line after context' do
    expect_offense(<<-RUBY)
      RSpec.context 'foo' do
        context 'bar' do
        end
        ^^^ Add an empty line after `context`.
        context 'baz' do
        end
      end
    RUBY
  end

  it 'approves empty line after describe' do
    expect_no_offenses(<<-RUBY)
      RSpec.describe Foo do
        describe '#bar' do
        end

        describe '#baz' do
        end
      end
    RUBY
  end

  it 'approves empty line after context' do
    expect_no_offenses(<<-RUBY)
      RSpec.context 'foo' do
        context 'bar' do
        end

        context 'baz' do
        end
      end
    RUBY
  end

  it 'handles describes in an if block' do
    expect_offense(<<-RUBY)
      if RUBY_VERSION < 2.3
        describe 'skips checks under old ruby' do
        end
      else
        describe 'first check' do
        end
        ^^^ Add an empty line after `describe`.
        describe 'second check' do
        end
      end
    RUBY
  end

  bad_example = <<-RUBY
    RSpec.describe Foo do
      describe '#bar' do
      end
      describe '#baz' do
      end
    end
  RUBY

  good_example = <<-RUBY
    RSpec.describe Foo do
      describe '#bar' do
      end

      describe '#baz' do
      end
    end
  RUBY

  include_examples 'autocorrect',
                   bad_example,
                   good_example
end
