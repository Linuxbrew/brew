require "rubocops/rubocop-cask"
require "test/rubocops/cask/shared_examples/cask_cop"

describe RuboCop::Cop::Cask::NoDslVersion do
  include CaskCop

  subject(:cop) { described_class.new }

  context "with header method `cask`" do
    let(:header_method) { "cask" }

    context "with no dsl version" do
      let(:source) { "cask 'foo' do; end" }

      include_examples "does not report any offenses"
    end

    context "with dsl version" do
      let(:source) { "cask :v1 => 'foo' do; end" }
      let(:correct_source) { "cask 'foo' do; end" }
      let(:expected_offenses) do
        [{
          message:  "Use `cask 'foo'` instead of `cask :v1 => 'foo'`",
          severity: :convention,
          line:     1,
          column:   0,
          source:   "cask :v1 => 'foo'",
        }]
      end

      include_examples "reports offenses"

      include_examples "autocorrects source"
    end
  end
end
