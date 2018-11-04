RSpec.describe RuboCop::Cop::RSpec::HookArgument, :config do
  subject(:cop) { described_class.new(config) }

  let(:cop_config) do
    { 'EnforcedStyle' => enforced_style }
  end

  shared_examples 'ignored hooks' do
    it 'ignores :context and :suite' do
      expect_no_offenses(<<-RUBY)
        before(:suite) { true }
        after(:suite) { true }
        before(:context) { true }
        after(:context) { true }
      RUBY
    end

    it 'ignores hooks with more than one argument' do
      expect_no_offenses(<<-RUBY)
        before(:each, :something_custom) { true }
      RUBY
    end

    it 'ignores non-rspec hooks' do
      expect_no_offenses(<<-RUBY)
        setup(:each) { true }
      RUBY
    end
  end

  shared_examples 'hook autocorrect' do |output|
    include_examples 'autocorrect', 'before(:each) { }', output
    include_examples 'autocorrect', 'before(:example) { }', output
    include_examples 'autocorrect', 'before { }', output

    include_examples 'autocorrect', 'config.before(:each) { }',
                     'config.' + output
    include_examples 'autocorrect', 'config.before(:example) { }',
                     'config.' + output
    include_examples 'autocorrect', 'config.before { }',
                     'config.' + output
  end

  shared_examples 'an example hook' do
    include_examples 'ignored hooks'
    include_examples 'detects style', 'before(:each) { foo }', 'each'
    include_examples 'detects style', 'before(:example) { foo }', 'example'
    include_examples 'detects style', 'before { foo }', 'implicit'
  end

  context 'when EnforcedStyle is :implicit' do
    let(:enforced_style) { :implicit }

    it 'detects :each for hooks' do
      expect_offense(<<-RUBY)
        before(:each) { true }
        ^^^^^^^^^^^^^ Omit the default `:each` argument for RSpec hooks.
        after(:each)  { true }
        ^^^^^^^^^^^^ Omit the default `:each` argument for RSpec hooks.
        around(:each) { true }
        ^^^^^^^^^^^^^ Omit the default `:each` argument for RSpec hooks.
        config.after(:each)  { true }
        ^^^^^^^^^^^^^^^^^^^ Omit the default `:each` argument for RSpec hooks.
      RUBY
    end

    it 'detects :example for hooks' do
      expect_offense(<<-RUBY)
        before(:example) { true }
        ^^^^^^^^^^^^^^^^ Omit the default `:example` argument for RSpec hooks.
        after(:example)  { true }
        ^^^^^^^^^^^^^^^ Omit the default `:example` argument for RSpec hooks.
        around(:example) { true }
        ^^^^^^^^^^^^^^^^ Omit the default `:example` argument for RSpec hooks.
        config.before(:example) { true }
        ^^^^^^^^^^^^^^^^^^^^^^^ Omit the default `:example` argument for RSpec hooks.
      RUBY
    end

    it 'does not flag hooks without default scopes' do
      expect_no_offenses(<<-RUBY)
        before { true }
        after { true }
        config.before { true }
      RUBY
    end

    include_examples 'an example hook'
    include_examples 'hook autocorrect', 'before { }'
  end

  context 'when EnforcedStyle is :each' do
    let(:enforced_style) { :each }

    it 'detects :each for hooks' do
      expect_no_offenses(<<-RUBY)
        before(:each) { true }
        after(:each)  { true }
        around(:each) { true }
        config.before(:each) { true }
      RUBY
    end

    it 'detects :example for hooks' do
      expect_offense(<<-RUBY)
        before(:example) { true }
        ^^^^^^^^^^^^^^^^ Use `:each` for RSpec hooks.
        after(:example)  { true }
        ^^^^^^^^^^^^^^^ Use `:each` for RSpec hooks.
        around(:example) { true }
        ^^^^^^^^^^^^^^^^ Use `:each` for RSpec hooks.
        config.before(:example) { true }
        ^^^^^^^^^^^^^^^^^^^^^^^ Use `:each` for RSpec hooks.
      RUBY
    end

    it 'detects hooks without default scopes' do
      expect_offense(<<-RUBY)
        before { true }
        ^^^^^^ Use `:each` for RSpec hooks.
        after { true }
        ^^^^^ Use `:each` for RSpec hooks.
        config.before { true }
               ^^^^^^ Use `:each` for RSpec hooks.
      RUBY
    end

    include_examples 'an example hook'
    include_examples 'hook autocorrect', 'before(:each) { }'
  end

  context 'when EnforcedStyle is :example' do
    let(:enforced_style) { :example }

    it 'detects :example for hooks' do
      expect_no_offenses(<<-RUBY)
        before(:example) { true }
        after(:example)  { true }
        around(:example) { true }
        config.before(:example) { true }
      RUBY
    end

    it 'detects :each for hooks' do
      expect_offense(<<-RUBY)
        before(:each) { true }
        ^^^^^^^^^^^^^ Use `:example` for RSpec hooks.
        after(:each)  { true }
        ^^^^^^^^^^^^ Use `:example` for RSpec hooks.
        around(:each) { true }
        ^^^^^^^^^^^^^ Use `:example` for RSpec hooks.
        config.before(:each) { true }
        ^^^^^^^^^^^^^^^^^^^^ Use `:example` for RSpec hooks.
      RUBY
    end

    it 'does not flag hooks without default scopes' do
      expect_offense(<<-RUBY)
        before { true }
        ^^^^^^ Use `:example` for RSpec hooks.
        after { true }
        ^^^^^ Use `:example` for RSpec hooks.
        config.before { true }
               ^^^^^^ Use `:example` for RSpec hooks.
      RUBY
    end

    include_examples 'an example hook'
    include_examples 'hook autocorrect', 'before(:example) { }'
  end
end
