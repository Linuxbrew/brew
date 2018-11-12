RSpec.describe RuboCop::Cop::RSpec::DescribeClass do
  subject(:cop) { described_class.new }

  it 'checks first-line describe statements' do
    expect_offense(<<-RUBY)
      describe "bad describe" do
               ^^^^^^^^^^^^^^ The first argument to describe should be the class or module being tested.
      end
    RUBY
  end

  it 'supports RSpec.describe' do
    expect_no_offenses(<<-RUBY)
      RSpec.describe Foo do
      end
    RUBY
  end

  it 'checks describe statements after a require' do
    expect_offense(<<-RUBY)
      require 'spec_helper'
      describe "bad describe" do
               ^^^^^^^^^^^^^^ The first argument to describe should be the class or module being tested.
      end
    RUBY
  end

  it 'checks highlights the first argument of a describe' do
    expect_offense(<<-RUBY)
      describe "bad describe", "blah blah" do
               ^^^^^^^^^^^^^^ The first argument to describe should be the class or module being tested.
      end
    RUBY
  end

  it 'ignores nested describe statements' do
    expect_no_offenses(<<-RUBY)
      describe Some::Class do
        describe "bad describe" do
        end
      end
    RUBY
  end

  it 'ignores request specs' do
    expect_no_offenses(<<-RUBY)
      describe 'my new feature', type: :request do
      end
    RUBY
  end

  it 'ignores feature specs' do
    expect_no_offenses(<<-RUBY)
      describe 'my new feature', type: :feature do
      end
    RUBY
  end

  it 'ignores system specs' do
    expect_no_offenses(<<-RUBY)
      describe 'my new system test', type: :system do
      end
    RUBY
  end

  it 'ignores feature specs when RSpec.describe is used' do
    expect_no_offenses(<<-RUBY)
      RSpec.describe 'my new feature', type: :feature do
      end
    RUBY
  end

  it 'flags specs with non :type metadata' do
    expect_offense(<<-RUBY)
      describe 'my new feature', foo: :feature do
               ^^^^^^^^^^^^^^^^ The first argument to describe should be the class or module being tested.
      end
    RUBY
  end

  it 'flags normal metadata in describe' do
    expect_offense(<<-RUBY)
      describe 'my new feature', blah, type: :wow do
               ^^^^^^^^^^^^^^^^ The first argument to describe should be the class or module being tested.
      end
    RUBY
  end

  it 'ignores feature specs - also with complex options' do
    expect_no_offenses(<<-RUBY)
      describe 'my new feature', :test, :type => :feature, :foo => :bar do
      end
    RUBY
  end

  it 'ignores an empty describe' do
    expect_no_offenses(<<-RUBY)
      RSpec.describe do
      end

      describe do
      end
    RUBY
  end

  it 'ignores routing specs' do
    expect_no_offenses(<<-RUBY)
      describe 'my new route', type: :routing do
      end
    RUBY
  end

  it 'ignores view specs' do
    expect_no_offenses(<<-RUBY)
      describe 'widgets/index', type: :view do
      end
    RUBY
  end

  it "doesn't blow up on single-line describes" do
    expect_no_offenses('describe Some::Class')
  end

  it "doesn't flag top level describe in a shared example" do
    expect_no_offenses(<<-RUBY)
      shared_examples 'Common::Interface' do
        describe '#public_interface' do
          it 'conforms to interface' do
            # ...
          end
        end
      end
    RUBY
  end

  it "doesn't flag top level describe in a shared context" do
    expect_no_offenses(<<-RUBY)
      RSpec.shared_context 'Common::Interface' do
        describe '#public_interface' do
          it 'conforms to interface' do
            # ...
          end
        end
      end
    RUBY
  end

  it "doesn't flag top level describe in an unnamed shared context" do
    expect_no_offenses(<<-RUBY)
      shared_context do
        describe '#public_interface' do
          it 'conforms to interface' do
            # ...
          end
        end
      end
    RUBY
  end
end
