RSpec.describe RuboCop::Cop::RSpec::InstanceSpy do
  subject(:cop) { described_class.new }

  context 'when used with `have_received`' do
    it 'adds an offense for an instance_double with single argument' do
      expect_offense(<<-RUBY)
        it do
          foo = instance_double(Foo).as_null_object
                ^^^^^^^^^^^^^^^^^^^^ Use `instance_spy` when you check your double with `have_received`.
          expect(foo).to have_received(:bar)
        end
      RUBY
    end

    it 'adds an offense for an instance_double with multiple arguments' do
      expect_offense(<<-RUBY)
        it do
          foo = instance_double(Foo, :name).as_null_object
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `instance_spy` when you check your double with `have_received`.
          expect(foo).to have_received(:bar)
        end
      RUBY
    end

    it 'ignores instance_double when it is not used with as_null_object' do
      expect_no_offenses(<<-RUBY)
        it do
          foo = instance_double(Foo)
          expect(bar).to have_received(:bar)
       end
      RUBY
    end
  end

  context 'when not used with `have_received`' do
    it 'does not add an offence' do
      expect_no_offenses(<<-RUBY)
        it do
          foo = instance_double(Foo).as_null_object
          expect(bar).to have_received(:bar)
        end
      RUBY
    end
  end

  original = <<-RUBY
    it do
      foo = instance_double(Foo, :name).as_null_object
      expect(foo).to have_received(:bar)
    end
  RUBY
  corrected = <<-RUBY
    it do
      foo = instance_spy(Foo, :name)
      expect(foo).to have_received(:bar)
    end
  RUBY

  include_examples 'autocorrect', original, corrected
end
