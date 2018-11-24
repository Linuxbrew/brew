RSpec.describe RuboCop::Cop::RSpec::OverwritingSetup do
  subject(:cop) { described_class.new }

  it 'finds overwriten `let`' do
    expect_offense(<<-RUBY)
      RSpec.describe User do
        let(:a) { a }
        let(:a) { b }
        ^^^^^^^^^^^^^ `a` is already defined.
      end
    RUBY
  end

  it 'finds overwriten `subject`' do
    expect_offense(<<-RUBY)
      RSpec.describe User do
        subject(:a) { a }

        let(:a) { b }
        ^^^^^^^^^^^^^ `a` is already defined.
      end
    RUBY
  end

  it 'works with `subject!` and `let!`' do
    expect_offense(<<-RUBY)
      RSpec.describe User do
        subject!(:a) { a }

        let!(:a) { b }
        ^^^^^^^^^^^^^^ `a` is already defined.
      end
    RUBY
  end

  it 'finds `let!` overwriting `let`' do
    expect_offense(<<-RUBY)
      RSpec.describe User do
        let(:a) { b }
        let!(:a) { b }
        ^^^^^^^^^^^^^^ `a` is already defined.
      end
    RUBY
  end

  it 'ignores overwriting in different context' do
    expect_no_offenses(<<-RUBY)
      RSpec.describe User do
        let(:a) { a }

        context `different` do
          let(:a) { b }
        end
      end
    RUBY
  end

  it 'handles unnamed subjects' do
    expect_offense(<<-RUBY)
      RSpec.describe User do
        subject { a }

        let(:subject) { b }
        ^^^^^^^^^^^^^^^^^^^ `subject` is already defined.
      end
    RUBY
  end

  it 'handles dynamic names for `let`' do
    expect_no_offenses(<<-RUBY)
      RSpec.describe User do
        subject(:name) { a }

        let(name) { b }
      end
    RUBY
  end

  it 'handles string arguments' do
    expect_offense(<<-RUBY)
      RSpec.describe User do
        subject(:name) { a }

        let("name") { b }
        ^^^^^^^^^^^^^^^^^ `name` is already defined.
      end
    RUBY
  end
end
