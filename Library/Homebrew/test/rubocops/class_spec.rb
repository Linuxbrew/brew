require "rubocops/class"

describe RuboCop::Cop::FormulaAudit::ClassName do
  subject(:cop) { described_class.new }

  it "reports an offense when using ScriptFileFormula" do
    expect_offense(<<~RUBY)
      class Foo < ScriptFileFormula
                  ^^^^^^^^^^^^^^^^^ ScriptFileFormula is deprecated, use Formula instead
        url 'https://example.com/foo-1.0.tgz'
      end
    RUBY
  end

  it "reports an offense when using GithubGistFormula" do
    expect_offense(<<~RUBY)
      class Foo < GithubGistFormula
                  ^^^^^^^^^^^^^^^^^ GithubGistFormula is deprecated, use Formula instead
        url 'https://example.com/foo-1.0.tgz'
      end
    RUBY
  end

  it "reports an offense when using AmazonWebServicesFormula" do
    expect_offense(<<~RUBY)
      class Foo < AmazonWebServicesFormula
                  ^^^^^^^^^^^^^^^^^^^^^^^^ AmazonWebServicesFormula is deprecated, use Formula instead
        url 'https://example.com/foo-1.0.tgz'
      end
    RUBY
  end

  it "supports auto-correcting deprecated parent classes" do
    source = <<~RUBY
      class Foo < AmazonWebServicesFormula
        url 'https://example.com/foo-1.0.tgz'
      end
    RUBY

    corrected_source = <<~RUBY
      class Foo < Formula
        url 'https://example.com/foo-1.0.tgz'
      end
    RUBY

    new_source = autocorrect_source(source)
    expect(new_source).to eq(corrected_source)
  end
end

describe RuboCop::Cop::FormulaAudit::TestCalls do
  subject(:cop) { described_class.new }

  it "reports an offense when /usr/local/bin is found in test calls" do
    expect_offense(<<~RUBY)
      class Foo < Formula
        url 'https://example.com/foo-1.0.tgz'

        test do
          system "/usr/local/bin/test"
                 ^^^^^^^^^^^^^^^^^^^^^ use \#{bin} instead of /usr/local/bin in system
        end
      end
    RUBY
  end

  it "reports an offense when passing 0 as the second parameter to shell_output" do
    expect_offense(<<~RUBY)
      class Foo < Formula
        url 'https://example.com/foo-1.0.tgz'

        test do
          shell_output("\#{bin}/test", 0)
                                      ^ Passing 0 to shell_output() is redundant
        end
      end
    RUBY
  end

  it "supports auto-correcting test calls" do
    source = <<~RUBY
      class Foo < Formula
        url 'https://example.com/foo-1.0.tgz'

        test do
          shell_output("/usr/local/sbin/test", 0)
        end
      end
    RUBY

    corrected_source = <<~RUBY
      class Foo < Formula
        url 'https://example.com/foo-1.0.tgz'

        test do
          shell_output("\#{sbin}/test")
        end
      end
    RUBY

    new_source = autocorrect_source(source)
    expect(new_source).to eq(corrected_source)
  end
end

describe RuboCop::Cop::FormulaAuditStrict::Test do
  subject(:cop) { described_class.new }

  it "reports an offense when there is no test block" do
    expect_offense(<<~RUBY)
      class Foo < Formula
      ^^^^^^^^^^^^^^^^^^^ A `test do` test block should be added
        url 'https://example.com/foo-1.0.tgz'
      end
    RUBY
  end

  it "reports an offense when there is an empty test block" do
    expect_offense(<<~RUBY)
      class Foo < Formula
        url 'https://example.com/foo-1.0.tgz'

        test do
        ^^^^^^^ `test do` should not be empty
        end
      end
    RUBY
  end

  it "reports an offense when test is falsely true" do
    expect_offense(<<~RUBY)
      class Foo < Formula
        url 'https://example.com/foo-1.0.tgz'

        test do
        ^^^^^^^ `test do` should contain a real test
          true
        end
      end
    RUBY
  end
end
