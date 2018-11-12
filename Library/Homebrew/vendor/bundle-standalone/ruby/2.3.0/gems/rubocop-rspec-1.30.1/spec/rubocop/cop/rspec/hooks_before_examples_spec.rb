RSpec.describe RuboCop::Cop::RSpec::HooksBeforeExamples do
  subject(:cop) { described_class.new }

  it 'flags `before` after `it`' do
    expect_offense(<<-RUBY)
      RSpec.describe User do
        it { is_expected.to be_after_let }
        before { setup }
        ^^^^^^^^^^^^^^^^ Move `before` above the examples in the group.
      end
    RUBY
  end

  it 'flags `before` after `context`' do
    expect_offense(<<-RUBY)
      RSpec.describe User do
        context 'a context' do
          it { is_expected.to be_after_let }
        end

        before { setup }
        ^^^^^^^^^^^^^^^^ Move `before` above the examples in the group.
      end
    RUBY
  end

  it 'flags `before` after `include_examples`' do
    expect_offense(<<-RUBY)
      RSpec.describe User do
        include_examples('should be after let')

        before { setup }
        ^^^^^^^^^^^^^^^^ Move `before` above the examples in the group.
      end
    RUBY
  end

  it 'flags `after` after an example' do
    expect_offense(<<-RUBY)
      RSpec.describe User do
        it { is_expected.to be_after_let }
        after { cleanup }
        ^^^^^^^^^^^^^^^^^ Move `after` above the examples in the group.
      end
    RUBY
  end

  it 'flags scoped hook after an example' do
    expect_offense(<<-RUBY)
      RSpec.describe User do
        it { is_expected.to be_after_let }
        before(:each) { cleanup }
        ^^^^^^^^^^^^^^^^^^^^^^^^^ Move `before` above the examples in the group.
      end
    RUBY
  end

  it 'does not flag hooks before the examples' do
    expect_no_offenses(<<-RUBY)
      RSpec.describe User do
        before(:each) { setup }
        after(:each) { cleanup }

        it { is_expected.to be_after_let }

        context 'a context' do
          it { is_expected.to work }
        end

        include_examples('everything is fine')
      end
    RUBY
  end

  it 'does not flag `before` in a nested context' do
    expect_no_offenses(<<-RUBY)
      RSpec.describe User do
        before { setup }

        context 'something else' do
          before { additional_setup }
          it { is_expected.to work }
        end

        include_examples('everything is fine')
      end
    RUBY
  end

  it 'allows inclusion of context before hooks' do
    expect_no_offenses(<<-RUBY)
      RSpec.describe User do
        include_context 'special user'

        before { setup }
      end
    RUBY
  end

  it 'ignores single-line example blocks' do
    expect_no_offenses(<<-RUBY)
      RSpec.describe User do
        include_examples 'special user' do
          before { setup }
        end
      end
    RUBY
  end

  bad_code = <<-RUBY
    RSpec.describe User do
      include_examples('should be after hook')
      context 'another one' do
        before { another_setup }
        include_examples('should be ok')
      end

      after { cleanup }
    end
  RUBY

  good_code = <<-RUBY
    RSpec.describe User do
      after { cleanup }
      include_examples('should be after hook')
      context 'another one' do
        before { another_setup }
        include_examples('should be ok')
      end

    end
  RUBY

  include_examples 'autocorrect', bad_code, good_code
end
