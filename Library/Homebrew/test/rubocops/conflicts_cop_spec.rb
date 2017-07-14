require "rubocop"
require "rubocop/rspec/support"
require_relative "../../extend/string"
require_relative "../../rubocops/conflicts_cop"

describe RuboCop::Cop::FormulaAudit::Conflicts do
  subject(:cop) { described_class.new }

  context "When auditing formula for conflicts with" do
    it "multiple conflicts_with" do
      source = <<-EOS.undent
        class FooAT20 < Formula
          url 'http://example.com/foo-2.0.tgz'
          conflicts_with "mysql", "mariadb", "percona-server",
                           :because => "both install plugins"
        end
      EOS

      expected_offenses = [{  message: described_class::MSG,
                              severity: :convention,
                              line: 3,
                              column: 2,
                              source: source }]

      inspect_source(cop, source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "no conflicts_with" do
      source = <<-EOS.undent
        class FooAT20 < Formula
          url 'http://example.com/foo-2.0.tgz'
          desc 'Bar'
        end
      EOS
      inspect_source(cop, source)
      expect(cop.offenses).to eq([])
    end
  end
end
