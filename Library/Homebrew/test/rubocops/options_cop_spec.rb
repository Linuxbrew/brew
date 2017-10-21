require_relative "../../rubocops/options_cop"

describe RuboCop::Cop::FormulaAudit::Options do
  subject(:cop) { described_class.new }

  it "reports an offense when using the 32-bit option" do
    expect_offense(<<~RUBY)
      class Foo < Formula
        url 'http://example.com/foo-1.0.tgz'
        option "32-bit", "with 32-bit"
                ^^^^^^ macOS has been 64-bit only since 10.6 so 32-bit options are deprecated.
      end
    RUBY
  end
end

describe RuboCop::Cop::FormulaAuditStrict::Options do
  subject(:cop) { described_class.new }

  context "When auditing options strictly" do
    it "with universal" do
      expect_offense(<<~RUBY)
        class Foo < Formula
          url 'http://example.com/foo-1.0.tgz'
          option :universal
          ^^^^^^^^^^^^^^^^^ macOS has been 64-bit only since 10.6 so universal options are deprecated.
        end
      RUBY
    end

    it "with deprecated options" do
      expect_offense(<<~RUBY)
        class Foo < Formula
          url 'http://example.com/foo-1.0.tgz'
          option :cxx11
          option "examples", "with-examples"
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Options should begin with with/without. Migrate '--examples' with `deprecated_option`.
        end
      RUBY
    end

    it "with misc deprecated options" do
      expect_offense(<<~RUBY)
        class Foo < Formula
          url 'http://example.com/foo-1.0.tgz'
          option "without-check"
          ^^^^^^^^^^^^^^^^^^^^^^ Use '--without-test' instead of '--without-check'. Migrate '--without-check' with `deprecated_option`.
        end
      RUBY
    end
  end
end

describe RuboCop::Cop::NewFormulaAudit::Options do
  subject(:cop) { described_class.new }

  context "When auditing options for a new formula" do
    it "with deprecated options" do
      expect_offense(<<~RUBY)
        class Foo < Formula
          url 'http://example.com/foo-1.0.tgz'
          deprecated_option "examples" => "with-examples"
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ New Formula should not use `deprecated_option`
        end
      RUBY
    end
  end
end
