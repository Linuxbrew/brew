require "rubocop"
require "rubocop/rspec/support"
require_relative "../../extend/string"
require_relative "../../rubocops/components_order_cop"

describe RuboCop::Cop::FormulaAuditStrict::ComponentsOrder do
  subject(:cop) { described_class.new }

  context "When auditing formula components order" do
    it "When url precedes homepage" do
      source = <<-EOS.undent
        class Foo < Formula
          url "http://example.com/foo-1.0.tgz"
          homepage "http://example.com"
        end
      EOS

      expected_offenses = [{  message: "`homepage` (line 3) should be put before `url` (line 2)",
                              severity: :convention,
                              line: 3,
                              column: 2,
                              source: source }]

      inspect_source(cop, source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "When `resource` precedes `depends_on`" do
      source = <<-EOS.undent
        class Foo < Formula
          url "https://example.com/foo-1.0.tgz"

          resource "foo2" do
            url "https://example.com/foo-2.0.tgz"
          end

          depends_on "openssl"
        end
      EOS

      expected_offenses = [{  message: "`depends_on` (line 8) should be put before `resource` (line 4)",
                              severity: :convention,
                              line: 8,
                              column: 2,
                              source: source }]

      inspect_source(cop, source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "When `test` precedes `plist`" do
      source = <<-EOS.undent
        class Foo < Formula
          url "https://example.com/foo-1.0.tgz"

          test do
            expect(shell_output("./dogs")).to match("Dogs are terrific")
          end

          def plist
          end
        end
      EOS

      expected_offenses = [{  message: "`plist` (line 8) should be put before `test` (line 4)",
                              severity: :convention,
                              line: 8,
                              column: 2,
                              source: source }]

      inspect_source(cop, source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "When only one of many `depends_on` precedes `conflicts_with`" do
      source = <<-EOS.undent
        class Foo < Formula
          depends_on "autoconf" => :build
          conflicts_with "visionmedia-watch"
          depends_on "automake" => :build
          depends_on "libtool" => :build
          depends_on "pkg-config" => :build
          depends_on "gettext"
        end
      EOS

      expected_offenses = [{  message: "`depends_on` (line 4) should be put before `conflicts_with` (line 3)",
                              severity: :convention,
                              line: 4,
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

  context "When auditing formula components order with autocorrect" do
    it "When url precedes homepage" do
      source = <<-EOS.undent
        class Foo < Formula
          url "http://example.com/foo-1.0.tgz"
          homepage "http://example.com"
        end
      EOS
      correct_source = <<-EOS.undent
        class Foo < Formula
          homepage "http://example.com"
          url "http://example.com/foo-1.0.tgz"
        end
      EOS

      corrected_source = autocorrect_source(cop, source)
      expect(corrected_source).to eq(correct_source)
    end

    it "When `resource` precedes `depends_on`" do
      source = <<-EOS.undent
        class Foo < Formula
          url "https://example.com/foo-1.0.tgz"

          resource "foo2" do
            url "https://example.com/foo-2.0.tgz"
          end

          depends_on "openssl"
        end
      EOS
      correct_source = <<-EOS.undent
        class Foo < Formula
          url "https://example.com/foo-1.0.tgz"

          depends_on "openssl"

          resource "foo2" do
            url "https://example.com/foo-2.0.tgz"
          end
        end
      EOS
      corrected_source = autocorrect_source(cop, source)
      expect(corrected_source).to eq(correct_source)
    end
  end
end
