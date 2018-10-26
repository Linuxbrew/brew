require "rubocops/text"

describe RuboCop::Cop::FormulaAudit::Text do
  subject(:cop) { described_class.new }

  context "When auditing formula text" do
    it "with both openssl and libressl optional dependencies" do
      expect_offense(<<~RUBY)
        class Foo < Formula
          url "https://example.com/foo-1.0.tgz"
          homepage "https://example.com"

          depends_on "openssl"
          depends_on "libressl" => :optional
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Formulae should not depend on both OpenSSL and LibreSSL (even optionally).
        end
      RUBY
    end

    it "with both openssl and libressl dependencies" do
      expect_offense(<<~RUBY)
        class Foo < Formula
          url "https://example.com/foo-1.0.tgz"
          homepage "https://example.com"

          depends_on "openssl"
          depends_on "libressl"
          ^^^^^^^^^^^^^^^^^^^^^ Formulae should not depend on both OpenSSL and LibreSSL (even optionally).
        end
      RUBY
    end

    it "When xcodebuild is called without SYMROOT" do
      expect_offense(<<~RUBY)
        class Foo < Formula
          url "https://example.com/foo-1.0.tgz"
          homepage "https://example.com"

          def install
            xcodebuild "-project", "meow.xcodeproject"
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ xcodebuild should be passed an explicit \"SYMROOT\"
          end
        end
      RUBY
    end

    it "When xcodebuild is called without any args" do
      expect_offense(<<~RUBY)
        class Foo < Formula
          url "https://example.com/foo-1.0.tgz"
          homepage "https://example.com"

          def install
            xcodebuild
            ^^^^^^^^^^ xcodebuild should be passed an explicit \"SYMROOT\"
          end
        end
      RUBY
    end

    it "When go get is executed" do
      expect_offense(<<~RUBY)
        class Foo < Formula
          url "https://example.com/foo-1.0.tgz"
          homepage "https://example.com"

          def install
            system "go", "get", "bar"
            ^^^^^^^^^^^^^^^^^^^^^^^^^ Do not use `go get`. Please ask upstream to implement Go vendoring
          end
        end
      RUBY
    end

    it "When xcodebuild is executed" do
      expect_offense(<<~RUBY)
        class Foo < Formula
          url "https://example.com/foo-1.0.tgz"
          homepage "https://example.com"

          def install
            system "xcodebuild", "foo", "bar"
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ use \"xcodebuild *args\" instead of \"system 'xcodebuild', *args\"
          end
        end
      RUBY
    end

    it "When scons is executed" do
      expect_offense(<<~RUBY)
        class Foo < Formula
          url "https://example.com/foo-1.0.tgz"
          homepage "https://example.com"

          def install
            system "scons", "foo", "bar"
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ use \"scons *args\" instead of \"system 'scons', *args\"
          end
        end
      RUBY
    end

    it "When plist_options are not defined when using a formula-defined plist", :ruby23 do
      expect_offense(<<~RUBY)
        class Foo < Formula
          url "https://example.com/foo-1.0.tgz"
          homepage "https://example.com"

          def install
            system "xcodebuild", "foo", "bar"
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ use \"xcodebuild *args\" instead of \"system 'xcodebuild', *args\"
          end

          def plist
          ^^^^^^^^^ Please set plist_options when using a formula-defined plist.
            <<~XML
              <?xml version="1.0" encoding="UTF-8"?>
              <!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
              <plist version="1.0">
              <dict>
                <key>Label</key>
                <string>org.nrpe.agent</string>
              </dict>
              </plist>
            XML
          end
        end
      RUBY
    end

    it "When language/go is require'd" do
      expect_offense(<<~RUBY)
        require "language/go"
        ^^^^^^^^^^^^^^^^^^^^^ require "language/go" is unnecessary unless using `go_resource`s

        class Foo < Formula
          url "https://example.com/foo-1.0.tgz"
          homepage "https://example.com"

          def install
            system "go", "get", "bar"
            ^^^^^^^^^^^^^^^^^^^^^^^^^ Do not use `go get`. Please ask upstream to implement Go vendoring
          end
        end
      RUBY
    end

    it "When formula uses virtualenv and also `setuptools` resource" do
      expect_offense(<<~RUBY)
        class Foo < Formula
          url "https://example.com/foo-1.0.tgz"
          homepage "https://example.com"

          resource "setuptools" do
          ^^^^^^^^^^^^^^^^^^^^^ Formulae using virtualenvs do not need a `setuptools` resource.
            url "https://foo.com/foo.tar.gz"
            sha256 "db0904a28253cfe53e7dedc765c71596f3c53bb8a866ae50123320ec1a7b73fd"
          end

          def install
            virtualenv_create(libexec)
          end
        end
      RUBY
    end

    it "When Formula.factory(name) is used" do
      expect_offense(<<~RUBY)
        class Foo < Formula
          url "https://example.com/foo-1.0.tgz"
          homepage "https://example.com"

          def install
            Formula.factory(name)
            ^^^^^^^^^^^^^^^^^^^^^ \"Formula.factory(name)\" is deprecated in favor of \"Formula[name]\"
          end
        end
      RUBY
    end

    it "When dep ensure is used without `-vendor-only`" do
      expect_offense(<<~RUBY)
        class Foo < Formula
          url "https://example.com/foo-1.0.tgz"
          homepage "https://example.com"

          def install
            system "dep", "ensure"
            ^^^^^^^^^^^^^^^^^^^^^^ use \"dep\", \"ensure\", \"-vendor-only\"
          end
        end
      RUBY
    end

    it "When cargo build is executed" do
      expect_offense(<<~RUBY)
        class Foo < Formula
          url "https://example.com/foo-1.0.tgz"
          homepage "https://example.com"

          def install
            system "cargo", "build"
            ^^^^^^^^^^^^^^^^^^^^^^^ use \"cargo\", \"install\", \"--root\", prefix, \"--path\", \".\"
          end
        end
      RUBY
    end
  end
end
