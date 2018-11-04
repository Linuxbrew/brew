require 'yard'

require 'rubocop/rspec/description_extractor'

RSpec.describe RuboCop::RSpec::DescriptionExtractor do
  let(:yardocs) do
    YARD.parse_string(<<-RUBY)
      # This is not a cop
      class RuboCop::Cop::Mixin::Sneaky
      end

      # This is not a concrete cop
      #
      # @abstract
      class RuboCop::Cop::RSpec::Cop
      end

      # Checks foo
      #
      # Some description
      #
      # @note only works with foo
      class RuboCop::Cop::RSpec::Foo < RuboCop::Cop::RSpec::Cop
        # Hello
        def bar
        end

        # :nodoc:
        class HelperClassForFoo
        end
      end

      class RuboCop::Cop::RSpec::Undocumented < RuboCop::Cop::RSpec::Cop
        # Hello
        def bar
        end
      end
    RUBY

    YARD::Registry.all
  end

  def stub_cop_const(name)
    stub_const(
      "RuboCop::Cop::RSpec::#{name}",
      Class.new(RuboCop::Cop.const_get(:WorkaroundCop))
    )
  end

  before do
    stub_cop_const('Foo')
    stub_cop_const('Undocumented')
  end

  it 'builds a hash of descriptions' do
    expect(described_class.new(yardocs).to_h).to eql(
      'RSpec/Foo'          => { 'Description' => 'Checks foo' },
      'RSpec/Undocumented' => { 'Description' => ''           }
    )
  end
end
