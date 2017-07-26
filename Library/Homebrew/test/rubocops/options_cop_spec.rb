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

describe RuboCop::Cop::FormulaAuditStrict::Options do
  subject(:cop) { described_class.new }

  context "When auditing options strictly" do
    it "with universal" do
      source = <<-EOS.undent
        class Foo < Formula
          url 'http://example.com/foo-1.0.tgz'
          option :universal
        end
      EOS

      expected_offenses = [{  message: described_class::DEPRECATION_MSG,
                              severity: :convention,
                              line: 3,
                              column: 2,
                              source: source }]

      inspect_source(cop, source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "with deprecated options" do
      source = <<-EOS.undent
        class Foo < Formula
          url 'http://example.com/foo-1.0.tgz'
          option :cxx11
          option "examples", "with-examples"
        end
      EOS

      MSG_1 = "Options should begin with with/without."\
              " Migrate '--examples' with `deprecated_option`.".freeze
      expected_offenses = [{  message: MSG_1,
                              severity: :convention,
                              line: 4,
                              column: 2,
                              source: source }]

      inspect_source(cop, source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "with misc deprecated options" do
      source = <<-EOS.undent
        class Foo < Formula
          url 'http://example.com/foo-1.0.tgz'
          option "without-check"
        end
      EOS

      MSG_2 = "Use '--without-test' instead of '--without-check'."\
              " Migrate '--without-check' with `deprecated_option`.".freeze
      expected_offenses = [{  message: MSG_2,
                              severity: :convention,
                              line: 3,
                              column: 2,
                              source: source }]

      inspect_source(cop, source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end
  end
end

describe RuboCop::Cop::NewFormulaAudit::Options do
  subject(:cop) { described_class.new }

  context "When auditing options for a new formula" do
    it "with deprecated options" do
      source = <<-EOS.undent
        class Foo < Formula
          url 'http://example.com/foo-1.0.tgz'
          deprecated_option "examples" => "with-examples"
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
  end
end
