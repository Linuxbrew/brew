require "rubocop"
require "rubocop/rspec/support"
require_relative "../../extend/string"
require_relative "../../rubocops/class_cop"

describe RuboCop::Cop::FormulaAudit::ClassName do
  subject(:cop) { described_class.new }

  context "When auditing formula" do
    it "with deprecated inheritance" do
      formulas = [{
        "class" => "GithubGistFormula",
      }, {
        "class" => "ScriptFileFormula",
      }, {
        "class" => "AmazonWebServicesFormula",
      }]

      formulas.each do |formula|
        source = <<-EOS.undent
        class Foo < #{formula["class"]}
          url 'http://example.com/foo-1.0.tgz'
        end
        EOS

        expected_offenses = [{  message: "#{formula["class"]} is deprecated, use Formula instead",
                                severity: :convention,
                                line: 1,
                                column: 12,
                                source: source }]

        inspect_source(cop, source)

        expected_offenses.zip(cop.offenses.reverse).each do |expected, actual|
          expect_offense(expected, actual)
        end
      end
    end

    it "with deprecated inheritance and autocorrect" do
      source = <<-EOS.undent
        class Foo < AmazonWebServicesFormula
          url 'http://example.com/foo-1.0.tgz'
        end
      EOS
      corrected_source = <<-EOS.undent
        class Foo < Formula
          url 'http://example.com/foo-1.0.tgz'
        end
      EOS

      new_source = autocorrect_source(cop, source)
      expect(new_source).to eq(corrected_source)
    end
  end
end

describe RuboCop::Cop::FormulaAuditStrict::Test do
  subject(:cop) { described_class.new }

  context "When auditing formula" do
    it "without a test block" do
      source = <<-EOS.undent
        class Foo < Formula
          url 'http://example.com/foo-1.0.tgz'
        end
      EOS
      expected_offenses = [{  message: described_class::MSG,
                              severity: :convention,
                              line: 1,
                              column: 0,
                              source: source }]

      inspect_source(cop, source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end
  end
end
