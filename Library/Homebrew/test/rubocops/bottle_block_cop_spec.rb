require "rubocop"
require "rubocop/rspec/support"
require_relative "../../extend/string"
require_relative "../../rubocops/bottle_block_cop"

describe RuboCop::Cop::FormulaAuditStrict::BottleBlock do
  subject(:cop) { described_class.new }

  context "When auditing Bottle Block" do
    it "When there is revision in bottle block" do
      source = <<-EOS.undent
        class Foo < Formula
          url 'http://example.com/foo-1.0.tgz'
          bottle do
            cellar :any
            revision 2
          end
        end
      EOS

      expected_offenses = [{  message: described_class::MSG,
                              severity: :convention,
                              line: 5,
                              column: 4,
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

  context "When auditing Bottle Block with auto correct" do
    it "When there is revision in bottle block" do
      source = <<-EOS.undent
        class Foo < Formula
          url 'http://example.com/foo-1.0.tgz'
          bottle do
            cellar :any
            revision 2
          end
        end
      EOS
      corrected_source = <<-EOS.undent
        class Foo < Formula
          url 'http://example.com/foo-1.0.tgz'
          bottle do
            cellar :any
            rebuild 2
          end
        end
      EOS

      new_source = autocorrect_source(cop, source)
      expect(new_source).to eq(corrected_source)
    end
  end
end
