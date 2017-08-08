require "rubocop"
require "rubocop/rspec/support"
require_relative "../../extend/string"
require_relative "../../rubocops/text_cop"

describe RuboCop::Cop::FormulaAudit::Text do
  subject(:cop) { described_class.new }

  context "When auditing formula text" do
    it "with both openssl and libressl optional dependencies" do
      source = <<-EOS.undent
        class Foo < Formula
          url "http://example.com/foo-1.0.tgz"
          homepage "http://example.com"

          depends_on "openssl"
          depends_on "libressl" => :optional
        end
      EOS

      expected_offenses = [{  message: "Formulae should not depend on both OpenSSL and LibreSSL (even optionally).",
                              severity: :convention,
                              line: 6,
                              column: 2,
                              source: source }]

      inspect_source(cop, source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "with both openssl and libressl dependencies" do
      source = <<-EOS.undent
        class Foo < Formula
          url "http://example.com/foo-1.0.tgz"
          homepage "http://example.com"

          depends_on "openssl"
          depends_on "libressl"
        end
      EOS

      expected_offenses = [{  message: "Formulae should not depend on both OpenSSL and LibreSSL (even optionally).",
                              severity: :convention,
                              line: 6,
                              column: 2,
                              source: source }]

      inspect_source(cop, source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "When xcodebuild is called without SYMROOT" do
      source = <<-EOS.undent
        class Foo < Formula
          url "http://example.com/foo-1.0.tgz"
          homepage "http://example.com"

          def install
            xcodebuild "-project", "meow.xcodeproject"
          end
        end
      EOS

      expected_offenses = [{  message: "xcodebuild should be passed an explicit \"SYMROOT\"",
                              severity: :convention,
                              line: 6,
                              column: 4,
                              source: source }]

      inspect_source(cop, source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "When xcodebuild is called without any args" do
      source = <<-EOS.undent
        class Foo < Formula
          url "http://example.com/foo-1.0.tgz"
          homepage "http://example.com"

          def install
            xcodebuild
          end
        end
      EOS

      expected_offenses = [{  message: "xcodebuild should be passed an explicit \"SYMROOT\"",
                              severity: :convention,
                              line: 6,
                              column: 4,
                              source: source }]

      inspect_source(cop, source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "When go get is executed" do
      source = <<-EOS.undent
        class Foo < Formula
          url "http://example.com/foo-1.0.tgz"
          homepage "http://example.com"

          def install
            system "go", "get", "bar"
          end
        end
      EOS

      expected_offenses = [{  message: "Formulae should not use `go get`. If non-vendored resources are required use `go_resource`s.",
                              severity: :convention,
                              line: 6,
                              column: 4,
                              source: source }]

      inspect_source(cop, source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "When xcodebuild is executed" do
      source = <<-EOS.undent
        class Foo < Formula
          url "http://example.com/foo-1.0.tgz"
          homepage "http://example.com"

          def install
            system "xcodebuild", "foo", "bar"
          end
        end
      EOS

      expected_offenses = [{  message: "use \"xcodebuild *args\" instead of \"system 'xcodebuild', *args\"",
                              severity: :convention,
                              line: 6,
                              column: 4,
                              source: source }]

      inspect_source(cop, source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "When scons is executed" do
      source = <<-EOS.undent
        class Foo < Formula
          url "http://example.com/foo-1.0.tgz"
          homepage "http://example.com"

          def install
            system "scons", "foo", "bar"
          end
        end
      EOS

      expected_offenses = [{  message: "use \"scons *args\" instead of \"system 'scons', *args\"",
                              severity: :convention,
                              line: 6,
                              column: 4,
                              source: source }]

      inspect_source(cop, source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "When plist_options are not defined when using a formula-defined plist" do
      source = <<-EOS.undent
        class Foo < Formula
          url "http://example.com/foo-1.0.tgz"
          homepage "http://example.com"

          def install
            system "xcodebuild", "foo", "bar"
          end

          def plist; <<-EOS.undent
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0">
            <dict>
              <key>Label</key>
              <string>org.nrpe.agent</string>
            </dict>
            </plist>
            \EOS
          end
        end
      EOS

      expected_offenses = [{  message: "Please set plist_options when using a formula-defined plist.",
                              severity: :convention,
                              line: 9,
                              column: 2,
                              source: source }]

      inspect_source(cop, source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "When language/go is require'd" do
      source = <<-EOS.undent
        require "language/go"

        class Foo < Formula
          url "http://example.com/foo-1.0.tgz"
          homepage "http://example.com"

          def install
            system "go", "get", "bar"
          end
        end
      EOS

      expected_offenses = [{  message: "require \"language/go\" is unnecessary unless using `go_resource`s",
                              severity: :convention,
                              line: 1,
                              column: 0,
                              source: source }]

      inspect_source(cop, source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "When formula uses virtualenv and also `setuptools` resource" do
      source = <<-EOS.undent
        class Foo < Formula
          url "http://example.com/foo-1.0.tgz"
          homepage "http://example.com"

          resource "setuptools" do
            url "https://foo.com/foo.tar.gz"
            sha256 "db0904a28253cfe53e7dedc765c71596f3c53bb8a866ae50123320ec1a7b73fd"
          end

          def install
            virtualenv_create(libexec)
          end
        end
      EOS

      expected_offenses = [{  message: "Formulae using virtualenvs do not need a `setuptools` resource.",
                              severity: :convention,
                              line: 5,
                              column: 2,
                              source: source }]

      inspect_source(cop, source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "When Formula.factory(name) is used" do
      source = <<-EOS.undent
        class Foo < Formula
          url "http://example.com/foo-1.0.tgz"
          homepage "http://example.com"

          def install
            Formula.factory(name)
          end
        end
      EOS

      expected_offenses = [{  message: "\"Formula.factory(name)\" is deprecated in favor of \"Formula[name]\"",
                              severity: :convention,
                              line: 6,
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
end
