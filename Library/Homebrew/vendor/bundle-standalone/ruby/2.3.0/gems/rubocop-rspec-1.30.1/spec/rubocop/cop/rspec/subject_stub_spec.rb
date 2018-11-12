# frozen_string_literal: true

RSpec.describe RuboCop::Cop::RSpec::SubjectStub do
  subject(:cop) { described_class.new }

  it 'complains when subject is stubbed' do
    expect_offense(<<-RUBY)
      describe Foo do
        subject(:foo) { described_class.new }

        before do
          allow(foo).to receive(:bar).and_return(baz)
          ^^^^^^^^^^ Do not stub your test subject.
        end

        it 'uses expect twice' do
          expect(foo.bar).to eq(baz)
        end
      end
    RUBY
  end

  it 'complains when subject is mocked' do
    expect_offense(<<-RUBY)
      describe Foo do
        subject(:foo) { described_class.new }

        before do
          expect(foo).to receive(:bar).and_return(baz)
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not stub your test subject.
          expect(foo).to receive(:bar)
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not stub your test subject.
          expect(foo).to receive(:bar).with(1)
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not stub your test subject.
          expect(foo).to receive(:bar).with(1).and_return(2)
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not stub your test subject.
        end

        it 'uses expect twice' do
          expect(foo.bar).to eq(baz)
        end
      end
    RUBY
  end

  it 'ignores stub within context where subject name changed' do
    expect_no_offenses(<<-RUBY)
      describe Foo do
        subject(:foo) { described_class.new }

        context 'when I shake things up' do
          subject(:bar) { described_class.new }

          it 'tries to trick rubocop-rspec' do
            allow(foo).to receive(:baz)
          end
        end
      end
    RUBY
  end

  it 'ignores stub when inside all matcher' do
    expect_no_offenses(<<-RUBY)
      describe Foo do
        subject(:foo) { [Object.new] }
        it 'tries to trick rubocop-rspec' do
          expect(foo).to all(receive(:baz))
        end
      end
    RUBY
  end

  it 'flags nested subject stubs when nested subject uses same name' do
    expect_offense(<<-RUBY)
      describe Foo do
        subject(:foo) { described_class.new }

        context 'when I shake things up' do
          subject(:foo) { described_class.new }

          before do
            allow(foo).to receive(:wow)
            ^^^^^^^^^^ Do not stub your test subject.
          end

          it 'tries to trick rubocop-rspec' do
            expect(foo).to eql(:neat)
          end
        end
      end
    RUBY
  end

  it 'ignores nested stubs when nested subject is anonymous' do
    expect_no_offenses(<<-RUBY)
      describe Foo do
        subject(:foo) { described_class.new }

        context 'when I shake things up' do
          subject { described_class.new }

          before do
            allow(foo).to receive(:wow)
          end

          it 'tries to trick rubocop-rspec' do
            expect(foo).to eql(:neat)
          end
        end
      end
    RUBY
  end

  it 'flags nested subject stubs when example group does not define subject' do
    expect_offense(<<-RUBY)
      describe Foo do
        subject(:foo) { described_class.new }

        context 'when I shake things up' do
          before do
            allow(foo).to receive(:wow)
            ^^^^^^^^^^ Do not stub your test subject.
          end

          it 'tries to trick rubocop-rspec' do
            expect(foo).to eql(:neat)
          end
        end
      end
    RUBY
  end

  it 'flags nested subject stubs' do
    expect_offense(<<-RUBY)
      describe Foo do
        subject(:foo) { described_class.new }

        context 'when I shake things up' do
          subject(:bar) { described_class.new }

          before do
            allow(foo).to receive(:wow)
            allow(bar).to receive(:wow)
            ^^^^^^^^^^ Do not stub your test subject.
          end

          it 'tries to trick rubocop-rspec' do
            expect(bar).to eql(foo)
          end
        end
      end
    RUBY
  end

  it 'flags nested subject stubs when adjacent context redefines' do
    expect_offense(<<-RUBY)
      describe Foo do
        subject(:foo) { described_class.new }

        context 'when I do something in a context' do
          subject { blah }
        end

        it 'still flags this test' do
          allow(foo).to receive(:blah)
          ^^^^^^^^^^ Do not stub your test subject.
        end
      end
    RUBY
  end

  it 'flags deeply nested subject stubs' do
    expect_offense(<<-RUBY)
      describe Foo do
        subject(:foo) { described_class.new }

        context 'level 1' do
          subject(:bar) { described_class.new }

          context 'level 2' do
            subject(:baz) { described_class.new }

            before do
              allow(foo).to receive(:wow)
              allow(bar).to receive(:wow)
              allow(baz).to receive(:wow)
              ^^^^^^^^^^ Do not stub your test subject.
            end
          end
        end
      end
    RUBY
  end
end
