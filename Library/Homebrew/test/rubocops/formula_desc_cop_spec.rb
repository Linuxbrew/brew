require "rubocop"
require "rubocop/rspec/support"
require_relative "../../extend/string"
require_relative "../../rubocops/formula_desc_cop"

describe RuboCop::Cop::FormulaAuditStrict::FormulaDesc do
  subject(:cop) { described_class.new }

  context "When auditing formula desc" do
    it "When there is no desc" do
      source = <<-EOS.undent
        class Foo < Formula
          url 'http://example.com/foo-1.0.tgz'
        end
      EOS

      expected_offenses = [{  message: "Formula should have a desc (Description).",
                              severity: :convention,
                              line: 1,
                              column: 0,
                              source: source }]

      inspect_source(cop, source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "When desc is too long" do
      source = <<-EOS.undent
        class Foo < Formula
          url 'http://example.com/foo-1.0.tgz'
          desc '#{"bar"*30}'
        end
      EOS

      msg = <<-EOS.undent
        Description is too long. "name: desc" should be less than 80 characters.
        Length is calculated as Foo + desc. (currently 95)
      EOS
      expected_offenses = [{ message: msg,
                             severity: :convention,
                             line: 3,
                             column: 2,
                             source: source }]

      inspect_source(cop, source)
      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "When wrong \"command-line\" usage in desc" do
      source = <<-EOS.undent
        class Foo < Formula
          url 'http://example.com/foo-1.0.tgz'
          desc 'command line'
        end
      EOS

      expected_offenses = [{ message: "Description should use \"command-line\" instead of \"command line\"",
                             severity: :convention,
                             line: 3,
                             column: 8,
                             source: source }]

      inspect_source(cop, source)
      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "When an article is used in desc" do
      source = <<-EOS.undent
        class Foo < Formula
          url 'http://example.com/foo-1.0.tgz'
          desc 'An '
        end
      EOS

      expected_offenses = [{ message: "Description shouldn't start with an indefinite article (An )",
                             severity: :convention,
                             line: 3,
                             column: 8,
                             source: source }]

      inspect_source(cop, source)
      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "When formula name is in desc" do
      source = <<-EOS.undent
        class Foo < Formula
          url 'http://example.com/foo-1.0.tgz'
          desc 'Foo'
        end
      EOS

      expected_offenses = [{ message: "Description shouldn't include the formula name",
                             severity: :convention,
                             line: 3,
                             column: 8,
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
