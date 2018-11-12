RSpec.describe RuboCop::Cop::RSpec::DescribedClass, :config do
  subject(:cop) { described_class.new(config) }

  let(:cop_config) do
    { 'EnforcedStyle' => enforced_style }
  end

  shared_examples 'SkipBlocks enabled' do
    it 'does not flag violations within non-rspec blocks' do
      expect_offense(<<-RUBY)
        describe MyClass do
          controller(ApplicationController) do
            bar = MyClass
          end

          before do
            MyClass
            ^^^^^^^ Use `described_class` instead of `MyClass`.

            Foo.custom_block do
              MyClass
            end
          end
        end
      RUBY
    end
  end

  shared_examples 'SkipBlocks disabled' do
    it 'flags violations within all blocks' do
      expect_offense(<<-RUBY)
        describe MyClass do
          controller(ApplicationController) do
            bar = MyClass
                  ^^^^^^^ Use `described_class` instead of `MyClass`.
          end

          before(:each) do
            MyClass
            ^^^^^^^ Use `described_class` instead of `MyClass`.

            Foo.custom_block do
              MyClass
              ^^^^^^^ Use `described_class` instead of `MyClass`.
            end
          end
        end
      RUBY
    end
  end

  context 'when SkipBlocks is `true`' do
    let(:cop_config) { { 'SkipBlocks' => true } }

    include_examples 'SkipBlocks enabled'
  end

  context 'when SkipBlocks anything besides `true`' do
    let(:cop_config) { { 'SkipBlocks' => 'yes' } }

    include_examples 'SkipBlocks disabled'
  end

  context 'when SkipBlocks is not set' do
    let(:cop_config) { {} }

    include_examples 'SkipBlocks disabled'
  end

  context 'when SkipBlocks is `false`' do
    let(:cop_config) { { 'SkipBlocks' => false } }

    include_examples 'SkipBlocks disabled'
  end

  context 'when EnforcedStyle is :described_class' do
    let(:enforced_style) { :described_class }

    it 'checks for the use of the described class' do
      expect_offense(<<-RUBY)
        describe MyClass do
          include MyClass
                  ^^^^^^^ Use `described_class` instead of `MyClass`.

          subject { MyClass.do_something }
                    ^^^^^^^ Use `described_class` instead of `MyClass`.

          before { MyClass.do_something }
                   ^^^^^^^ Use `described_class` instead of `MyClass`.
        end
      RUBY
    end

    it 'ignores described class as string' do
      expect_no_offenses(<<-RUBY)
        describe MyClass do
          subject { "MyClass" }
        end
      RUBY
    end

    it 'ignores describe that do not reference to a class' do
      expect_no_offenses(<<-RUBY)
        describe "MyClass" do
          subject { "MyClass" }
        end
      RUBY
    end

    it 'ignores class if the scope is changing' do
      expect_no_offenses(<<-RUBY)
        describe MyClass do
          Class.new  { foo = MyClass }
          Module.new { bar = MyClass }

          def method
            include MyClass
          end

          class OtherClass
            include MyClass
          end

          module MyModle
            include MyClass
          end
        end
      RUBY
    end

    it 'only takes class from top level describes' do
      expect_offense(<<-RUBY)
        describe MyClass do
          describe MyClass::Foo do
            subject { MyClass::Foo }

            let(:foo) { MyClass }
                        ^^^^^^^ Use `described_class` instead of `MyClass`.
          end
        end
      RUBY
    end

    it 'ignores subclasses' do
      expect_no_offenses(<<-RUBY)
        describe MyClass do
          subject { MyClass::SubClass }
        end
      RUBY
    end

    it 'ignores if namespace is not matching' do
      expect_no_offenses(<<-RUBY)
        describe MyNamespace::MyClass do
          subject { ::MyClass }
          let(:foo) { MyClass }
        end
      RUBY
    end

    it 'checks for the use of described class with namespace' do
      expect_offense(<<-RUBY)
        describe MyNamespace::MyClass do
          subject { MyNamespace::MyClass }
                    ^^^^^^^^^^^^^^^^^^^^ Use `described_class` instead of `MyNamespace::MyClass`.
        end
      RUBY
    end

    it 'does not flag violations within a class scope change' do
      expect_no_offenses(<<-RUBY)
        describe MyNamespace::MyClass do
          before do
            class Foo
              thing = MyNamespace::MyClass.new
            end
          end
        end
      RUBY
    end

    it 'does not flag violations within a hook scope change' do
      expect_no_offenses(<<-RUBY)
        describe do
          before do
            MyNamespace::MyClass.new
          end
        end
      RUBY
    end

    it 'checks for the use of described class with module' do
      pending

      expect_offense(<<-RUBY)
        module MyNamespace
          describe MyClass do
            subject { MyNamespace::MyClass }
                      ^^^^^^^^^^^^^^^^^^^^ Use `described_class` instead of `MyNamespace::MyClass`
          end
        end
      RUBY
    end

    it 'accepts an empty block' do
      expect_no_offenses(<<-RUBY)
        describe MyClass do
        end
      RUBY
    end

    include_examples 'autocorrect',
                     'describe(Foo) { include Foo }',
                     'describe(Foo) { include described_class }'

    include_examples 'autocorrect',
                     'describe(Foo) { subject { Foo.do_action } }',
                     'describe(Foo) { subject { described_class.do_action } }'

    include_examples 'autocorrect',
                     'describe(Foo) { before { Foo.do_action } }',
                     'describe(Foo) { before { described_class.do_action } }'
  end

  context 'when EnforcedStyle is :explicit' do
    let(:enforced_style) { :explicit }

    it 'checks for the use of the described_class' do
      expect_offense(<<-RUBY)
        describe MyClass do
          include described_class
                  ^^^^^^^^^^^^^^^ Use `MyClass` instead of `described_class`.

          subject { described_class.do_something }
                    ^^^^^^^^^^^^^^^ Use `MyClass` instead of `described_class`.

          before { described_class.do_something }
                   ^^^^^^^^^^^^^^^ Use `MyClass` instead of `described_class`.
        end
      RUBY
    end

    it 'ignores described_class as string' do
      expect_no_offenses(<<-RUBY)
        describe MyClass do
          subject { "described_class" }
        end
      RUBY
    end

    it 'ignores describe that do not reference to a class' do
      expect_no_offenses(<<-RUBY)
        describe "MyClass" do
          subject { described_class }
        end
      RUBY
    end

    it 'does not flag violations within a class scope change' do
      expect_no_offenses(<<-RUBY)
        describe MyNamespace::MyClass do
          before do
            class Foo
              thing = described_class.new
            end
          end
        end
      RUBY
    end

    it 'does not flag violations within a hook scope change' do
      expect_no_offenses(<<-RUBY)
        describe do
          before do
            described_class.new
          end
        end
      RUBY
    end

    include_examples 'autocorrect',
                     'describe(Foo) { include described_class }',
                     'describe(Foo) { include Foo }'

    include_examples 'autocorrect',
                     'describe(Foo) { subject { described_class.do_action } }',
                     'describe(Foo) { subject { Foo.do_action } }'

    include_examples 'autocorrect',
                     'describe(Foo) { before { described_class.do_action } }',
                     'describe(Foo) { before { Foo.do_action } }'

    original = <<-RUBY
      describe(Foo) { include described_class }
      describe(Bar) { include described_class }
    RUBY
    corrected = <<-RUBY
      describe(Foo) { include Foo }
      describe(Bar) { include Bar }
    RUBY

    include_examples 'autocorrect', original, corrected
  end
end
