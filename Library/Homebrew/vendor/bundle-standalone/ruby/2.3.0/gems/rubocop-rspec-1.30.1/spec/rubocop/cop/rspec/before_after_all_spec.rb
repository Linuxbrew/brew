RSpec.describe RuboCop::Cop::RSpec::BeforeAfterAll do
  subject(:cop) { described_class.new }

  def message(hook)
    "Beware of using `#{hook}` as it may cause state to leak between tests. "\
    'If you are using `rspec-rails`, and `use_transactional_fixtures` is '\
    "enabled, then records created in `#{hook}` are not automatically rolled "\
    'back.'
  end

  context 'when using before all' do
    it 'registers an offense' do
      expect_offense(<<-RUBY)
        before(:all) { do_something }
        ^^^^^^^^^^^^ #{message('before(:all)')}
        before(:context) { do_something }
        ^^^^^^^^^^^^^^^^ #{message('before(:context)')}
      RUBY
    end
  end

  context 'when using after all' do
    it 'registers an offense' do
      expect_offense(<<-RUBY)
        after(:all) { do_something }
        ^^^^^^^^^^^ #{message('after(:all)')}
        after(:context) { do_something }
        ^^^^^^^^^^^^^^^ #{message('after(:context)')}
      RUBY
    end
  end

  context 'when using before each' do
    it 'does not register an offense' do
      expect_no_offenses(<<-RUBY)
        before(:each) { do_something }
        before(:example) { do_something }
      RUBY
    end
  end

  context 'when using after each' do
    it 'does not register an offense' do
      expect_no_offenses(<<-RUBY)
        after(:each) { do_something }
        after(:example) { do_something }
      RUBY
    end
  end
end
