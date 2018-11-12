RSpec.describe RuboCop::Cop::RSpec::ReturnFromStub, :config do
  subject(:cop) { described_class.new(config) }

  let(:cop_config) do
    { 'EnforcedStyle' => enforced_style }
  end

  context 'with EnforcedStyle `and_return`' do
    let(:enforced_style) { 'and_return' }

    it 'finds static values returned from block' do
      expect_offense(<<-RUBY)
        it do
          allow(Foo).to receive(:bar) { 42 }
                                      ^ Use `and_return` for static values.
        end
      RUBY
    end

    it 'finds empty values returned from block' do
      expect_offense(<<-RUBY)
        it do
          allow(Foo).to receive(:bar) {}
                                      ^ Use `and_return` for static values.
        end
      RUBY
    end

    it 'finds array with only static values returned from block' do
      expect_offense(<<-RUBY)
        it do
          allow(Foo).to receive(:bar) { [42, 43] }
                                      ^ Use `and_return` for static values.
        end
      RUBY
    end

    it 'finds hash with only static values returned from block' do
      expect_offense(<<-RUBY)
        it do
          allow(Foo).to receive(:bar) { {a: 42, b: 43} }
                                      ^ Use `and_return` for static values.
        end
      RUBY
    end

    it 'finds static values in a block when there are chained methods' do
      expect_offense(<<-RUBY)
        it do
          allow(Question).to receive(:meaning).with(:universe) { 42 }
                                                               ^ Use `and_return` for static values.
        end
      RUBY
    end

    it 'finds constants returned from block' do
      expect_offense(<<-RUBY)
        it do
          allow(Foo).to receive(:bar) { Life::MEANING }
                                      ^ Use `and_return` for static values.
        end
      RUBY
    end

    it 'finds nested constants returned from block' do
      expect_offense(<<-RUBY)
        it do
          allow(Foo).to receive(:bar) { {Life::MEANING => 42} }
                                      ^ Use `and_return` for static values.
        end
      RUBY
    end

    it 'ignores dynamic values returned from block' do
      expect_no_offenses(<<-RUBY)
        it do
          allow(Foo).to receive(:bar) { baz }
        end
      RUBY
    end

    it 'ignores variables return from block' do
      expect_no_offenses(<<-RUBY)
        it do
          $bar = 42
          baz = 123
          allow(Foo).to receive(:bar) { $bar }
          allow(Foo).to receive(:baz) { baz }
        end
      RUBY
    end

    it 'ignores array with dynamic values returned from block' do
      expect_no_offenses(<<-RUBY)
        it do
          allow(Foo).to receive(:bar) { [42, baz] }
        end
      RUBY
    end

    it 'ignores hash with dynamic values returned from block' do
      expect_no_offenses(<<-RUBY)
        it do
          allow(Foo).to receive(:bar) { {a: 42, b: baz} }
        end
      RUBY
    end

    it 'ignores block returning string with interpolation' do
      expect_no_offenses(<<-RUBY)
        it do
          bar = 42
          allow(Foo).to receive(:bar) { "You called \#{bar}" }
        end
      RUBY
    end

    it 'finds concatenated strings with no variables' do
      expect_offense(<<-RUBY)
        it do
          allow(Foo).to receive(:bar) do
                                      ^^ Use `and_return` for static values.
            "You called" \
            "me"
          end
        end
      RUBY
    end

    it 'ignores stubs without return value' do
      expect_no_offenses(<<-RUBY)
        it do
          allow(Foo).to receive(:bar)
        end
      RUBY
    end

    it 'handles stubs in a method' do
      expect_no_offenses(<<-RUBY)
        def stub_foo
          allow(Foo).to receive(:bar)
        end
      RUBY
    end

    include_examples 'autocorrect',
                     'allow(Foo).to receive(:bar) { 42 }',
                     'allow(Foo).to receive(:bar).and_return(42)'

    include_examples 'autocorrect',
                     'allow(Foo).to receive(:bar) { { foo: 42 } }',
                     'allow(Foo).to receive(:bar).and_return({ foo: 42 })'

    include_examples 'autocorrect',
                     'allow(Foo).to receive(:bar).with(1) { 42 }',
                     'allow(Foo).to receive(:bar).with(1).and_return(42)'

    include_examples 'autocorrect',
                     'allow(Foo).to receive(:bar) {}',
                     'allow(Foo).to receive(:bar).and_return(nil)'

    original = <<-RUBY
      allow(Foo).to receive(:bar) do
        'You called ' \\
        'me'
      end
    RUBY
    corrected = <<-RUBY
      allow(Foo).to receive(:bar).and_return('You called ' \\
        'me')
    RUBY

    include_examples 'autocorrect', original, corrected
  end

  context 'with EnforcedStyle `block`' do
    let(:enforced_style) { 'block' }

    it 'finds static values returned from method' do
      expect_offense(<<-RUBY)
        it do
          allow(Foo).to receive(:bar).and_return(42)
                                      ^^^^^^^^^^ Use block for static values.
        end
      RUBY
    end

    it 'finds static values returned from chained method' do
      expect_offense(<<-RUBY)
        it do
          allow(Foo).to receive(:bar).with(1).and_return(42)
                                              ^^^^^^^^^^ Use block for static values.
        end
      RUBY
    end

    it 'ignores dynamic values returned from method' do
      expect_no_offenses(<<-RUBY)
        it do
          allow(Foo).to receive(:bar).and_return(baz)
        end
      RUBY
    end

    it 'ignores string with interpolation returned from method' do
      expect_no_offenses(<<-RUBY)
        it do
          bar = 42
          allow(Foo).to receive(:bar).and_return("You called \#{bar}")
        end
      RUBY
    end

    it 'ignores multiple values being returned from method' do
      expect_no_offenses(<<-RUBY)
        it do
          allow(Foo).to receive(:bar).and_return(42, 43, 44)
        end
      RUBY
    end

    include_examples 'autocorrect',
                     'allow(Foo).to receive(:bar).and_return(42)',
                     'allow(Foo).to receive(:bar) { 42 }'

    include_examples 'autocorrect',
                     'allow(Foo).to receive(:bar).with(1).and_return(foo: 42)',
                     'allow(Foo).to receive(:bar).with(1) { { foo: 42 } }'

    include_examples 'autocorrect',
                     'allow(Foo).to receive(:bar).and_return({ foo: 42 })',
                     'allow(Foo).to receive(:bar) { { foo: 42 } }'

    include_examples 'autocorrect',
                     'allow(Foo).to receive(:bar).and_return(foo: 42)',
                     'allow(Foo).to receive(:bar) { { foo: 42 } }'

    original = <<-RUBY
      allow(Foo).to receive(:bar).and_return(
        a: 42,
        b: 43
      )
    RUBY
    corrected = <<-RUBY # Not perfect, but good enough.
      allow(Foo).to receive(:bar) { { a: 42,
        b: 43 } }
    RUBY

    include_examples 'autocorrect', original, corrected

    include_examples 'autocorrect',
                     'allow(Foo).to receive(:bar).and_return(nil)',
                     'allow(Foo).to receive(:bar) { nil }'

    original = <<-RUBY
      allow(Foo).to receive(:bar).and_return('You called ' \\
        'me')
    RUBY
    corrected = <<-RUBY
      allow(Foo).to receive(:bar) { 'You called ' \\
        'me' }
    RUBY

    include_examples 'autocorrect', original, corrected
  end
end
