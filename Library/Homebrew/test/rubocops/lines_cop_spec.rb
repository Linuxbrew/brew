require "rubocop"
require "rubocop/rspec/support"
require_relative "../../extend/string"
require_relative "../../rubocops/lines_cop"

describe RuboCop::Cop::FormulaAudit::Lines do
  subject(:cop) { described_class.new }

  context "When auditing lines" do
    it "with correctable deprecated dependencies" do
      formulae = [{
        "dependency" => :automake,
        "correct"    => "automake",
      }, {
        "dependency" => :autoconf,
        "correct"    => "autoconf",
      }, {
        "dependency" => :libtool,
        "correct"    => "libtool",
      }, {
        "dependency" => :apr,
        "correct"    => "apr-util",
      }, {
        "dependency" => :tex,
      }]

      formulae.each do |formula|
        source = <<-EOS.undent
        class Foo < Formula
          url 'http://example.com/foo-1.0.tgz'
          depends_on :#{formula["dependency"]}
        end
        EOS
        if formula.key?("correct")
          offense = ":#{formula["dependency"]} is deprecated. Usage should be \"#{formula["correct"]}\""
        else
          offense = ":#{formula["dependency"]} is deprecated"
        end
        expected_offenses = [{  message: offense,
                                severity: :convention,
                                line: 3,
                                column: 2,
                                source: source }]

        inspect_source(cop, source)

        expected_offenses.zip(cop.offenses.reverse).each do |expected, actual|
          expect_offense(expected, actual)
        end
      end
    end
  end
end

describe RuboCop::Cop::FormulaAudit::ClassInheritance do
  subject(:cop) { described_class.new }

  context "When auditing lines" do
    it "with no space in class inheritance" do
      source = <<-EOS.undent
        class Foo<Formula
          desc "foo"
          url 'http://example.com/foo-1.0.tgz'
        end
      EOS

      expected_offenses = [{  message: "Use a space in class inheritance: class Foo < Formula",
                              severity: :convention,
                              line: 1,
                              column: 10,
                              source: source }]

      inspect_source(cop, source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end
  end
end

describe RuboCop::Cop::FormulaAudit::Comments do
  subject(:cop) { described_class.new }

  context "When auditing formula" do
    it "with commented cmake call" do
      source = <<-EOS.undent
        class Foo < Formula
          desc "foo"
          url 'http://example.com/foo-1.0.tgz'
          # system "cmake", ".", *std_cmake_args
        end
      EOS

      expected_offenses = [{  message: "Please remove default template comments",
                              severity: :convention,
                              line: 4,
                              column: 2,
                              source: source }]

      inspect_source(cop, source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "with default template comments" do
      source = <<-EOS.undent
        class Foo < Formula
          # PLEASE REMOVE
          desc "foo"
          url 'http://example.com/foo-1.0.tgz'
        end
      EOS

      expected_offenses = [{  message: "Please remove default template comments",
                              severity: :convention,
                              line: 2,
                              column: 2,
                              source: source }]

      inspect_source(cop, source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "with commented out depends_on" do
      source = <<-EOS.undent
        class Foo < Formula
          desc "foo"
          url 'http://example.com/foo-1.0.tgz'
          # depends_on "foo"
        end
      EOS

      expected_offenses = [{  message: 'Commented-out dependency "foo"',
                              severity: :convention,
                              line: 4,
                              column: 2,
                              source: source }]

      inspect_source(cop, source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end
  end
end

describe RuboCop::Cop::FormulaAudit::Miscellaneous do
  subject(:cop) { described_class.new }

  context "When auditing formula" do
    it "with FileUtils" do
      source = <<-EOS.undent
        class Foo < Formula
          desc "foo"
          url 'http://example.com/foo-1.0.tgz'
          FileUtils.mv "hello"
        end
      EOS

      expected_offenses = [{  message: "Don't need 'FileUtils.' before mv",
                              severity: :convention,
                              line: 4,
                              column: 2,
                              source: source }]

      inspect_source(cop, source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "with long inreplace block vars" do
      source = <<-EOS.undent
        class Foo < Formula
          desc "foo"
          url 'http://example.com/foo-1.0.tgz'
          inreplace "foo" do |longvar|
            somerandomCall(longvar)
          end
        end
      EOS

      expected_offenses = [{  message: "\"inreplace <filenames> do |s|\" is preferred over \"|longvar|\".",
                              severity: :convention,
                              line: 4,
                              column: 2,
                              source: source }]

      inspect_source(cop, source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end
  end
end
