require_relative "../../rubocops/class_cop"

describe RuboCop::Cop::FormulaAudit::ClassName do
  subject(:cop) { described_class.new }

  it "reports an offense when using ScriptFileFormula" do
    expect_offense(<<~RUBY)
      class Foo < ScriptFileFormula
                  ^^^^^^^^^^^^^^^^^ ScriptFileFormula is deprecated, use Formula instead
        url 'http://example.com/foo-1.0.tgz'
      end
    RUBY
  end

  it "reports an offense when using GithubGistFormula" do
    expect_offense(<<~RUBY)
      class Foo < GithubGistFormula
                  ^^^^^^^^^^^^^^^^^ GithubGistFormula is deprecated, use Formula instead
        url 'http://example.com/foo-1.0.tgz'
      end
    RUBY
  end

  it "reports an offense when using AmazonWebServicesFormula" do
    expect_offense(<<~RUBY)
      class Foo < AmazonWebServicesFormula
                  ^^^^^^^^^^^^^^^^^^^^^^^^ AmazonWebServicesFormula is deprecated, use Formula instead
        url 'http://example.com/foo-1.0.tgz'
      end
    RUBY
  end

  it "supports auto-correcting deprecated parent classes" do
    source = <<~EOS
      class Foo < AmazonWebServicesFormula
        url 'http://example.com/foo-1.0.tgz'
      end
    EOS

    corrected_source = <<~EOS
      class Foo < Formula
        url 'http://example.com/foo-1.0.tgz'
      end
    EOS

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
        url 'http://example.com/foo-1.0.tgz'
      end
    RUBY
  end
end
