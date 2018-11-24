# frozen_string_literal: true

RSpec.describe RuboCop::Cop::RSpec::NestedGroups, :config do
  subject(:cop) { described_class.new(config) }

  it 'flags nested contexts' do
    expect_offense(<<-RUBY)
      describe MyClass do
        context 'when foo' do
          context 'when bar' do
            context 'when baz' do
            ^^^^^^^^^^^^^^^^^^ Maximum example group nesting exceeded [4/3].
            end
          end
        end

        context 'when qux' do
          context 'when norf' do
          end
        end
      end
    RUBY
  end

  it 'support --auto-gen-config' do
    inspect_source(<<-RUBY, 'spec/foo_spec.rb')
      describe MyClass do
        context 'when foo' do
          context 'when bar' do
            context 'when baz' do
            end
          end
        end
      end
    RUBY

    expect(cop.config_to_allow_offenses[:exclude_limit]).to eq('Max' => 4)
  end

  it 'ignores non-spec context methods' do
    expect_no_offenses(<<-RUBY)
      class MyThingy
        context 'this is not rspec' do
          context 'but it uses contexts' do
          end
        end
      end
    RUBY
  end

  context 'when Max is configured as 2' do
    let(:cop_config) { { 'Max' => '2' } }

    it 'flags two levels of nesting' do
      expect_offense(<<-RUBY)
        describe MyClass do
          context 'when foo' do
            context 'when bar' do
            ^^^^^^^^^^^^^^^^^^ Maximum example group nesting exceeded [3/2].
              context 'when baz' do
              ^^^^^^^^^^^^^^^^^^ Maximum example group nesting exceeded [4/2].
              end
            end
          end
        end
      RUBY
    end
  end

  context 'when configured with MaxNesting' do
    let(:cop_config) { { 'MaxNesting' => '1' } }

    it 'emits a deprecation warning' do
      expect { inspect_source('describe(Foo) { }', 'foo_spec.rb') }
        .to output(
          'Configuration key `MaxNesting` for RSpec/NestedGroups is ' \
          "deprecated in favor of `Max`. Please use that instead.\n"
        ).to_stderr
    end
  end
end
