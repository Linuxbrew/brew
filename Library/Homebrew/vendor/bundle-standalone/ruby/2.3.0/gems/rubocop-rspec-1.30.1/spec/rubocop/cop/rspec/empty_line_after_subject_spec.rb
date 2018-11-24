# frozen_string_literal: true

RSpec.describe RuboCop::Cop::RSpec::EmptyLineAfterSubject do
  subject(:cop) { described_class.new }

  it 'checks for empty line after subject' do
    expect_offense(<<-RUBY)
      RSpec.describe User do
        subject { described_class.new }
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Add empty line after `subject`.
        let(:params) { foo }
      end
    RUBY
  end

  it 'checks for empty line after subject!' do
    expect_offense(<<-RUBY)
      RSpec.describe User do
        subject! { described_class.new }
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Add empty line after `subject`.
        let(:params) { foo }
      end
    RUBY
  end

  it 'approves empty line after subject' do
    expect_no_offenses(<<-RUBY)
      RSpec.describe User do
        subject { described_class.new }

        let(:params) { foo }
      end
    RUBY
  end

  it 'approves empty line after subject!' do
    expect_no_offenses(<<-RUBY)
      RSpec.describe User do
        subject! { described_class.new }

        let(:params) { foo }
      end
    RUBY
  end

  it 'handles subjects in tests' do
    expect_no_offenses(<<-RUBY)
      RSpec.describe User do
        # This shouldn't really ever happen in a sane codebase but I still
        # want to avoid false positives
        it "doesn't mind me calling a method called subject in the test" do
          subject { bar }
          let(foo)
        end
      end
    RUBY
  end

  it 'handles multiline subject block' do
    expect_no_offenses(<<-RUBY)
      RSpec.describe User do
        subject do
          described_class.new
        end

        let(:params) { foo }
      end
    RUBY
  end

  it 'handles subject being the latest node' do
    expect_no_offenses(<<-RUBY)
      RSpec.describe User do
        subject { described_user }
      end
    RUBY
  end

  bad_example = <<-RUBY
  RSpec.describe User do
    subject { described_class.new }
    let(:params) { foo }
  end
  RUBY

  good_example = <<-RUBY
  RSpec.describe User do
    subject { described_class.new }

    let(:params) { foo }
  end
  RUBY

  include_examples 'autocorrect',
                   bad_example,
                   good_example
end
