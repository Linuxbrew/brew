require_relative "../../rubocops/components_order_cop"

describe RuboCop::Cop::FormulaAuditStrict::ComponentsOrder do
  subject(:cop) { described_class.new }

  context "When auditing formula components order" do
    it "When url precedes homepage" do
      expect_offense(<<~RUBY)
        class Foo < Formula
          url "http://example.com/foo-1.0.tgz"
          homepage "http://example.com"
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ `homepage` (line 3) should be put before `url` (line 2)
        end
      RUBY
    end

    it "When `resource` precedes `depends_on`" do
      expect_offense(<<~RUBY)
        class Foo < Formula
          url "https://example.com/foo-1.0.tgz"

          resource "foo2" do
            url "https://example.com/foo-2.0.tgz"
          end

          depends_on "openssl"
          ^^^^^^^^^^^^^^^^^^^^ `depends_on` (line 8) should be put before `resource` (line 4)
        end
      RUBY
    end

    it "When `test` precedes `plist`" do
      expect_offense(<<~RUBY)
        class Foo < Formula
          url "https://example.com/foo-1.0.tgz"

          test do
            expect(shell_output("./dogs")).to match("Dogs are terrific")
          end

          def plist
          ^^^^^^^^^ `plist` (line 8) should be put before `test` (line 4)
          end
        end
      RUBY
    end

    it "When only one of many `depends_on` precedes `conflicts_with`" do
      expect_offense(<<~RUBY)
        class Foo < Formula
          depends_on "autoconf" => :build
          conflicts_with "visionmedia-watch"
          depends_on "automake" => :build
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ `depends_on` (line 4) should be put before `conflicts_with` (line 3)
          depends_on "libtool" => :build
          depends_on "pkg-config" => :build
          depends_on "gettext"
        end
      RUBY
    end
  end

  context "When auditing formula components order with autocorrect" do
    it "When url precedes homepage" do
      source = <<~EOS
        class Foo < Formula
          url "http://example.com/foo-1.0.tgz"
          homepage "http://example.com"
        end
      EOS

      correct_source = <<~EOS
        class Foo < Formula
          homepage "http://example.com"
          url "http://example.com/foo-1.0.tgz"
        end
      EOS

      corrected_source = autocorrect_source(source)
      expect(corrected_source).to eq(correct_source)
    end

    it "When `resource` precedes `depends_on`" do
      source = <<~EOS
        class Foo < Formula
          url "https://example.com/foo-1.0.tgz"

          resource "foo2" do
            url "https://example.com/foo-2.0.tgz"
          end

          depends_on "openssl"
        end
      EOS

      correct_source = <<~EOS
        class Foo < Formula
          url "https://example.com/foo-1.0.tgz"

          depends_on "openssl"

          resource "foo2" do
            url "https://example.com/foo-2.0.tgz"
          end
        end
      EOS

      corrected_source = autocorrect_source(source)
      expect(corrected_source).to eq(correct_source)
    end
  end
end
