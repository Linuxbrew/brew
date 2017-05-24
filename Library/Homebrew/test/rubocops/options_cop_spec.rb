require "rubocop"
require "rubocop/rspec/support"
require_relative "../../extend/string"
require_relative "../../rubocops/options_cop"

describe RuboCop::Cop::FormulaAudit::Options do
  subject(:cop) { described_class.new }

  context "When auditing options" do
    it "32-bit" do
      source = <<-EOS.undent
        class Foo < Formula
          url 'http://example.com/foo-1.0.tgz'
          option "32-bit", "with 32-bit"
        end
      EOS

      expected_offenses = [{  message: described_class::DEPRECATION_MSG,
                              severity: :convention,
                              line: 3,
                              column: 10,
                              source: source }]

      inspect_source(cop, source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end
  end
end
