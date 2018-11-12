RSpec.describe RuboCop::Cop::RSpec::AroundBlock do
  subject(:cop) { described_class.new }

  context 'when no value is yielded' do
    it 'registers an offense' do
      expect_offense(<<-RUBY)
        around do
        ^^^^^^^^^ Test object should be passed to around block.
          do_something
        end
      RUBY
    end
  end

  context 'when the hook is scoped with a symbol' do
    it 'registers an offense' do
      expect_offense(<<-RUBY)
        around(:each) do
        ^^^^^^^^^^^^^^^^ Test object should be passed to around block.
          do_something
        end
      RUBY
    end
  end

  context 'when the yielded value is unused' do
    it 'registers an offense' do
      expect_offense(<<-RUBY)
        around do |test|
                   ^^^^ You should call `test.call` or `test.run`.
          do_something
        end
      RUBY
    end
  end

  context 'when two values are yielded and the first is unused' do
    it 'registers an offense for the first argument' do
      expect_offense(<<-RUBY)
        around do |test, unused|
                   ^^^^ You should call `test.call` or `test.run`.
          unused.run
        end
      RUBY
    end
  end

  context 'when the yielded value is referenced but not used' do
    it 'registers an offense' do
      expect_offense(<<-RUBY)
        around do |test|
                   ^^^^ You should call `test.call` or `test.run`.
          test
        end
      RUBY
    end
  end

  context 'when a method other than #run or #call is called' do
    it 'registers an offense' do
      expect_offense(<<-RUBY)
        around do |test|
                   ^^^^ You should call `test.call` or `test.run`.
          test.inspect
        end
      RUBY
    end
  end

  context 'when #run is called' do
    it 'does not register an offense' do
      expect_no_offenses(<<-RUBY)
        around do |test|
          test.run
        end
      RUBY
    end
  end

  context 'when #call is called' do
    it 'does not register an offense' do
      expect_no_offenses(<<-RUBY)
        around do |test|
          test.call
        end
      RUBY
    end
  end

  context 'when used as a block arg' do
    it 'does not register an offense' do
      expect_no_offenses(<<-RUBY)
        around do |test|
          1.times(&test)
        end
      RUBY
    end
  end

  context 'when passed to another method' do
    it 'does not register an offense' do
      expect_no_offenses(<<-RUBY)
        around do |test|
          something_that_might_run_test(test, another_arg)
        end
      RUBY
    end
  end

  context 'when yielded to another block' do
    it 'does not register an offense' do
      expect_no_offenses(<<-RUBY)
        around do |test|
          foo { yield(some_arg, test) }
        end
      RUBY
    end
  end
end
