# frozen_string_literal: true

RSpec.describe RuboCop::Cop::RSpec::LeadingSubject do
  subject(:cop) { described_class.new }

  it 'checks subject below let' do
    expect_offense(<<-RUBY)
      RSpec.describe User do
        let(:params) { foo }

        subject { described_class.new }
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Declare `subject` above any other `let` declarations.
      end
    RUBY
  end

  it 'checks subject below let!' do
    expect_offense(<<-RUBY)
      RSpec.describe User do
        let!(:params) { foo }

        subject { described_class.new }
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Declare `subject` above any other `let!` declarations.
      end
    RUBY
  end

  it 'approves of subject above let' do
    expect_no_offenses(<<-RUBY)
      RSpec.describe User do
        context 'blah' do
        end

        subject { described_class.new }

        let(:params) { foo }
      end
    RUBY
  end

  it 'handles subjects in contexts' do
    expect_no_offenses(<<-RUBY)
      RSpec.describe User do
        let(:params) { foo }

        context "when something happens" do
          subject { described_class.new }
        end
      end
    RUBY
  end

  it 'handles subjects in tests' do
    expect_no_offenses(<<-RUBY)
      RSpec.describe User do
        # This shouldn't really ever happen in a sane codebase but I still
        # want to avoid false positives
        it "doesn't mind me calling a method called subject in the test" do
          let(foo)
          subject { bar }
        end
      end
    RUBY
  end

  it 'checks subject below hook' do
    expect_offense(<<-RUBY)
      RSpec.describe User do
        before { allow(Foo).to receive(:bar) }

        subject { described_class.new }
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Declare `subject` above any other `before` declarations.
      end
    RUBY
  end

  it 'checks subject below example' do
    expect_offense(<<-RUBY)
      RSpec.describe User do
        it { is_expected.to be_present }

        subject { described_class.new }
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Declare `subject` above any other `it` declarations.
      end
    RUBY
  end

  bad_code = <<-RUBY
    RSpec.describe User do
      before { allow(Foo).to receive(:bar) }
      let(:params) { foo }
      let(:bar) { baz }

      subject { described_class.new }
      it { is_expected.to do_something }
    end
  RUBY

  good_code = <<-RUBY
    RSpec.describe User do
      subject { described_class.new }
      before { allow(Foo).to receive(:bar) }
      let(:params) { foo }
      let(:bar) { baz }

      it { is_expected.to do_something }
    end
  RUBY

  include_examples 'autocorrect', bad_code, good_code

  bad_code = <<-RUBY
    RSpec.describe User do
      let(:params) { foo }
      let(:bar) { baz }
      subject do
        described_class.new
      end
      it { is_expected.to do_something }
    end
  RUBY

  good_code = <<-RUBY
    RSpec.describe User do
      subject do
        described_class.new
      end
      let(:params) { foo }
      let(:bar) { baz }
      it { is_expected.to do_something }
    end
  RUBY

  include_examples 'autocorrect', bad_code, good_code
end
