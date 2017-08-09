require "rubocop"
require "rubocop/rspec/support"
require_relative "../../extend/string"
require_relative "../../rubocops/caveats_cop"

describe RuboCop::Cop::FormulaAudit::Caveats do
  subject(:cop) { described_class.new }

  context "When auditing caveats" do
    it "When there is setuid mentioned in caveats" do
      source = <<-EOS.undent
      class Foo < Formula
        homepage "http://example.com/foo"
        url "http://example.com/foo-1.0.tgz"

        def caveats
          "setuid"
        end
      end
      EOS

      expected_offenses = [{  message: "Don't recommend setuid in the caveats, suggest sudo instead.",
                              severity: :convention,
                              line: 6,
                              column: 5,
                              source: source }]

      inspect_source(cop, source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    def expect_offense(expected, actual)
      expect(actual.message).to eq(expected[:message])
      expect(actual.severity).to eq(expected[:severity])
      expect(actual.line).to eq(expected[:line])
      expect(actual.column).to eq(expected[:column])
    end
  end
end
