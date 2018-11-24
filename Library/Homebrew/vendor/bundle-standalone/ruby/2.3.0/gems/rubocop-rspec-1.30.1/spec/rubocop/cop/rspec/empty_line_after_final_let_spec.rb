# frozen_string_literal: true

RSpec.describe RuboCop::Cop::RSpec::EmptyLineAfterFinalLet do
  subject(:cop) { described_class.new }

  it 'checks for empty line after last let' do
    expect_offense(<<-RUBY)
      RSpec.describe User do
        let(:a) { a }
        let(:b) { b }
        ^^^^^^^^^^^^^ Add an empty line after the last `let` block.
        it { expect(a).to eq(b) }
      end
    RUBY
  end

  it 'check for empty line after the last `let!`' do
    expect_offense(<<-RUBY)
      RSpec.describe User do
        let(:a) { a }
        let!(:b) do
          b
        end
        ^^^ Add an empty line after the last `let` block.
        it { expect(a).to eq(b) }
      end
    RUBY
  end

  it 'approves empty line after let' do
    expect_no_offenses(<<-RUBY)
    RSpec.describe User do
      let(:a) { a }
      let(:b) { b }

      it { expect(a).to eq(b) }
    end
    RUBY
  end

  it 'allows comment followed by an empty line after let' do
    expect_no_offenses(<<-RUBY)
    RSpec.describe User do
      let(:a) { a }
      let(:b) { b }
      # end of setup

      it { expect(a).to eq(b) }
    end
    RUBY
  end

  it 'flags missing empty line after the comment that comes after last let' do
    expect_offense(<<-RUBY)
      RSpec.describe User do
        let(:a) { a }
        let(:b) { b }
        # end of setup
        ^^^^^^^^^^^^^^ Add an empty line after the last `let` block.
        it { expect(a).to eq(b) }
      end
    RUBY
  end

  it 'ignores empty lines between the lets' do
    expect_offense(<<-RUBY)
      RSpec.describe User do
        let(:a) { a }

        subject { described_class }

        let!(:b) { b }
        ^^^^^^^^^^^^^^ Add an empty line after the last `let` block.
        it { expect(a).to eq(b) }
      end
    RUBY
  end

  it 'handles let in tests' do
    expect_no_offenses(<<-RUBY)
      RSpec.describe User do
        # This shouldn't really ever happen in a sane codebase but I still
        # want to avoid false positives
        it "doesn't mind me calling a method called let in the test" do
          let(foo)
          subject { bar }
        end
      end
    RUBY
  end

  it 'handles multiline let block' do
    expect_no_offenses(<<-RUBY)
      RSpec.describe User do
        let(:a) { a }
        let(:b) do
          b
        end

        it { expect(a).to eq(b) }
      end
    RUBY
  end

  it 'handles let being the latest node' do
    expect_no_offenses(<<-RUBY)
      RSpec.describe User do
        let(:a) { a }
        let(:b) { b }
      end
    RUBY
  end

  it 'handles HEREDOC for let' do
    expect_no_offenses(<<-RUBY)
      RSpec.describe User do
        let(:foo) do
          <<-BAR
          hello
          world
          BAR
        end

        it 'uses heredoc' do
          expect(foo).to eql("  hello\n  world\n")
        end
      end
    RUBY
  end

  it 'handles silly HEREDOC syntax for let' do
    expect_no_offenses(<<-RUBY)
      RSpec.describe 'silly heredoc syntax' do
        let(:foo) { <<-BAR }
        hello
        world
        BAR

        it 'has tricky syntax' do
          expect(foo).to eql("  hello\n  world\n")
        end
      end
    RUBY
  end

  it 'handles silly HEREDOC offense' do
    expect_offense(<<-RUBY)
      RSpec.describe 'silly heredoc syntax' do
        let(:foo) { <<-BAR }
        hello
        world
        BAR
        ^^^ Add an empty line after the last `let` block.
        it 'has tricky syntax' do
          expect(foo).to eql("  hello\n  world\n")
        end
      end
    RUBY
  end

  bad_example = <<-RUBY
  RSpec.describe User do
    let(:params) { foo }
    it 'has a new line' do
    end
  end
  RUBY

  good_example = <<-RUBY
  RSpec.describe User do
    let(:params) { foo }

    it 'has a new line' do
    end
  end
  RUBY

  include_examples 'autocorrect',
                   bad_example,
                   good_example

  bad_example = <<-RUBY
  RSpec.describe User do
    let(:params) { foo }
    # a multiline comment marking
    # the end of setup
    it 'has a new line' do
    end
  end
  RUBY

  good_example = <<-RUBY
  RSpec.describe User do
    let(:params) { foo }
    # a multiline comment marking
    # the end of setup

    it 'has a new line' do
    end
  end
  RUBY

  include_examples 'autocorrect',
                   bad_example,
                   good_example

  bad_example = <<-RUBY
  RSpec.describe User do
    let(:params) { <<-DOC }
     I'm super annoying!
    DOC
    it 'has a new line' do
    end
  end
  RUBY

  good_example = <<-RUBY
  RSpec.describe User do
    let(:params) { <<-DOC }
     I'm super annoying!
    DOC

    it 'has a new line' do
    end
  end
  RUBY

  include_examples 'autocorrect',
                   bad_example,
                   good_example
end
