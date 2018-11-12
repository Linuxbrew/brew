# frozen_string_literal: true

RSpec.describe RuboCop::Cop::RSpec::RepeatedDescription do
  subject(:cop) { described_class.new }

  it 'registers an offense for repeated descriptions' do
    expect_offense(<<-RUBY)
      describe 'doing x' do
        it "does x" do
        ^^^^^^^^^^^ Don't repeat descriptions within an example group.
        end

        it "does x" do
        ^^^^^^^^^^^ Don't repeat descriptions within an example group.
        end
      end
    RUBY
  end

  it 'registers offense for repeated descriptions separated by a context' do
    expect_offense(<<-RUBY)
      describe 'doing x' do
        it "does x" do
        ^^^^^^^^^^^ Don't repeat descriptions within an example group.
        end

        context 'during some use case' do
          it "does x" do
            # this should be fine
          end
        end

        it "does x" do
        ^^^^^^^^^^^ Don't repeat descriptions within an example group.
        end
      end
    RUBY
  end

  it 'ignores descriptions repeated in a shared context' do
    expect_no_offenses(<<-RUBY)
      describe 'doing x' do
        it "does x" do
        end

        shared_context 'shared behavior' do
          it "does x" do
          end
        end
      end
    RUBY
  end

  it 'ignores repeated descriptions in a nested context' do
    expect_no_offenses(<<-RUBY)
      describe 'doing x' do
        it "does x" do
        end

        context 'in a certain use case' do
          it "does x" do
          end
        end
      end
    RUBY
  end

  it 'does not flag tests which do not contain description strings' do
    expect_no_offenses(<<-RUBY)
      describe 'doing x' do
        it { foo }
        it { bar }
      end
    RUBY
  end
end
