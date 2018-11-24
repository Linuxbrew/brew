RSpec.describe RuboCop::Cop::RSpec::InstanceVariable do
  subject(:cop) { described_class.new }

  it 'finds an instance variable inside a describe' do
    expect_offense(<<-RUBY)
      describe MyClass do
        before { @foo = [] }
        it { expect(@foo).to be_empty }
                    ^^^^ Replace instance variable with local variable or `let`.
      end
    RUBY
  end

  it 'ignores non-spec blocks' do
    expect_no_offenses(<<-RUBY)
      not_rspec do
        before { @foo = [] }
        it { expect(@foo).to be_empty }
      end
    RUBY
  end

  it 'finds an instance variable inside a shared example' do
    expect_offense(<<-RUBY)
      shared_examples 'shared example' do
        it { expect(@foo).to be_empty }
                    ^^^^ Replace instance variable with local variable or `let`.
      end
    RUBY
  end

  it 'ignores an instance variable without describe' do
    expect_no_offenses(<<-RUBY)
      @foo = []
      @foo.empty?
    RUBY
  end

  it 'ignores an instance variable inside a dynamic class' do
    expect_no_offenses(<<-RUBY)
      describe MyClass do
        let(:object) do
          Class.new(OtherClass) do
            def initialize(resource)
              @resource = resource
            end

            def serialize
              @resource.to_json
            end
          end
        end
      end
    RUBY
  end

  # Regression test for nevir/rubocop-rspec#115
  it 'ignores instance variables outside of specs' do
    expect_no_offenses(<<-RUBY, 'lib/source_code.rb')
      feature do
        @foo = bar

        @foo
      end
    RUBY
  end

  context 'when configured with AssignmentOnly', :config do
    subject(:cop) { described_class.new(config) }

    let(:cop_config) do
      { 'AssignmentOnly' => true }
    end

    it 'flags an instance variable when it is also assigned' do
      expect_offense(<<-RUBY)
        describe MyClass do
          before { @foo = [] }
          it { expect(@foo).to be_empty }
                      ^^^^ Replace instance variable with local variable or `let`.
        end
      RUBY
    end

    it 'ignores an instance variable when it is not assigned' do
      expect_no_offenses(<<-RUBY)
        describe MyClass do
          it { expect(@foo).to be_empty }
        end
      RUBY
    end
  end
end
