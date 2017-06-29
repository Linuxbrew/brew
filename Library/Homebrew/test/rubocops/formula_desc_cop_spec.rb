require "rubocop"
require "rubocop/rspec/support"
require_relative "../../extend/string"
require_relative "../../rubocops/formula_desc_cop"

describe RuboCop::Cop::FormulaAuditStrict::DescLength do
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
          desc 'Bar#{"bar" * 29}'
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

    it "When desc is multiline string" do
      source = <<-EOS.undent
        class Foo < Formula
          url 'http://example.com/foo-1.0.tgz'
          desc 'Bar#{"bar" * 9}'\
            '#{"foo" * 21}'
        end
      EOS

      msg = <<-EOS.undent
        Description is too long. "name: desc" should be less than 80 characters.
        Length is calculated as Foo + desc. (currently 98)
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
  end
end

describe RuboCop::Cop::FormulaAuditStrict::Desc do
  subject(:cop) { described_class.new }

  context "When auditing formula desc" do
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

      expected_offenses = [{ message: "Description shouldn't start with an indefinite article i.e. \"An\"",
                             severity: :convention,
                             line: 3,
                             column: 8,
                             source: source }]

      inspect_source(cop, source)
      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "When an lowercase letter starts a desc" do
      source = <<-EOS.undent
        class Foo < Formula
          url 'http://example.com/foo-1.0.tgz'
          desc 'bar'
        end
      EOS

      expected_offenses = [{ message: "Description should start with a capital letter",
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
          desc 'Foo is a foobar'
        end
      EOS

      expected_offenses = [{ message: "Description shouldn't start with the formula name",
                             severity: :convention,
                             line: 3,
                             column: 8,
                             source: source }]

      inspect_source(cop, source)
      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "autocorrects all rules" do
      source = <<-EOS.undent
        class Foo < Formula
          url 'http://example.com/foo-1.0.tgz'
          desc ' an bar: commandline foo '
        end
      EOS
      correct_source = <<-EOS.undent
        class Foo < Formula
          url 'http://example.com/foo-1.0.tgz'
          desc 'an bar: command-line'
        end
      EOS

      corrected_source = autocorrect_source(cop, source)
      expect(corrected_source).to eq(correct_source)
    end
  end
end
