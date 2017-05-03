require "rubocop"
require "rubocop/rspec/support"
require_relative "../../extend/string"
require_relative "../../rubocops/components_redundancy_cop"

describe RuboCop::Cop::FormulaAuditStrict::ComponentsRedundancy do
  subject(:cop) { described_class.new }

  context "When auditing formula components common errors" do
    it "When url outside stable block" do
      source = <<-EOS.undent
        class Foo < Formula
          url "http://example.com/foo-1.0.tgz"
          stable do
            # stuff
          end
        end
      EOS

      expected_offenses = [{  message: "`url` should be put inside `stable` block",
                              severity: :convention,
                              line: 2,
                              column: 2,
                              source: source }]

      inspect_source(cop, source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "When both `head` and `head do` are present" do
      source = <<-EOS.undent
        class Foo < Formula
          head "http://example.com/foo.git"
          head do
            # stuff
          end
        end
      EOS

      expected_offenses = [{  message: "`head` and `head do` should not be simultaneously present",
                              severity: :convention,
                              line: 3,
                              column: 2,
                              source: source }]

      inspect_source(cop, source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "When both `bottle :modifier` and `bottle do` are present" do
      source = <<-EOS.undent
        class Foo < Formula
          url "http://example.com/foo-1.0.tgz"
          bottle do
            # bottles go here
          end
          bottle :unneeded
        end
      EOS

      expected_offenses = [{  message: "`bottle :modifier` and `bottle do` should not be simultaneously present",
                              severity: :convention,
                              line: 3,
                              column: 2,
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
