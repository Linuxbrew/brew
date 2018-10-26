require "rubocops/formula_desc"

describe RuboCop::Cop::FormulaAudit::DescLength do
  subject(:cop) { described_class.new }

  context "When auditing formula desc" do
    it "When there is no desc" do
      expect_offense(<<~RUBY)
        class Foo < Formula
        ^^^^^^^^^^^^^^^^^^^ Formula should have a desc (Description).
          url 'https://example.com/foo-1.0.tgz'
        end
      RUBY
    end

    it "reports an offense when desc is an empty string" do
      expect_offense(<<~RUBY, "/homebrew-core/Formula/foo.rb")
        class Foo < Formula
          url 'https://example.com/foo-1.0.tgz'
          desc ''
          ^^^^^^^ The desc (description) should not be an empty string.
        end
      RUBY
    end

    it "When desc is too long" do
      expect_offense(<<~RUBY, "/homebrew-core/Formula/foo.rb")
        class Foo < Formula
          url 'https://example.com/foo-1.0.tgz'
          desc 'Bar#{"bar" * 29}'
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Description is too long. "name: desc" should be less than 80 characters. Length is calculated as foo + desc. (currently 95)
        end
      RUBY
    end

    it "When desc is multiline string" do
      expect_offense(<<~RUBY, "/homebrew-core/Formula/foo.rb")
        class Foo < Formula
          url 'https://example.com/foo-1.0.tgz'
          desc 'Bar#{"bar" * 9}'\
            '#{"foo" * 21}'
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Description is too long. "name: desc" should be less than 80 characters. Length is calculated as foo + desc. (currently 98)
        end
      RUBY
    end
  end
end

describe RuboCop::Cop::FormulaAuditStrict::Desc do
  subject(:cop) { described_class.new }

  context "When auditing formula desc" do
    it "When wrong \"command-line\" usage in desc" do
      expect_offense(<<~RUBY, "/homebrew-core/Formula/foo.rb")
        class Foo < Formula
          url 'https://example.com/foo-1.0.tgz'
          desc 'command line'
                ^ Description should start with a capital letter
                ^^^^^^^^^^^^ Description should use \"command-line\" instead of \"command line\"
        end
      RUBY
    end

    it "When an article is used in desc" do
      expect_offense(<<~RUBY, "/homebrew-core/Formula/foo.rb")
        class Foo < Formula
          url 'https://example.com/foo-1.0.tgz'
          desc 'An aardvark'
                ^^^ Description shouldn\'t start with an indefinite article i.e. \"An\"
        end
      RUBY
    end

    it "When an lowercase letter starts a desc" do
      expect_offense(<<~RUBY, "/homebrew-core/Formula/foo.rb")
        class Foo < Formula
          url 'https://example.com/foo-1.0.tgz'
          desc 'bar'
                ^ Description should start with a capital letter
        end
      RUBY
    end

    it "When formula name is in desc" do
      expect_offense(<<~RUBY, "/homebrew-core/Formula/foo.rb")
        class Foo < Formula
          url 'https://example.com/foo-1.0.tgz'
          desc 'Foo is a foobar'
                ^^^^ Description shouldn\'t start with the formula name
        end
      RUBY
    end

    it "When the description ends with a full stop" do
      expect_offense(<<~RUBY, "/homebrew-core/Formula/foo.rb")
        class Foo < Formula
          url 'https://example.com/foo-1.0.tgz'
          desc 'Description with a full stop at the end.'
                                                       ^ Description shouldn\'t end with a full stop
        end
      RUBY
    end

    it "When the description starts with a leading space" do
      expect_offense(<<~RUBY, "/homebrew-core/Formula/foo.rb")
        class Foo < Formula
          url 'https://example.com/foo-1.0.tgz'
          desc ' Description with a leading space'
                ^ Description shouldn\'t have a leading space
        end
      RUBY
    end

    it "When the description ends with a trailing space" do
      expect_offense(<<~RUBY, "/homebrew-core/Formula/foo.rb")
        class Foo < Formula
          url 'https://example.com/foo-1.0.tgz'
          desc 'Description with a trailing space '
                                                 ^ Description shouldn\'t have a trailing space
        end
      RUBY
    end

    it "autocorrects all rules" do
      source = <<~RUBY
        class Foo < Formula
          url 'https://example.com/foo-1.0.tgz'
          desc ' an bar: commandline foo '
        end
      RUBY

      correct_source = <<~RUBY
        class Foo < Formula
          url 'https://example.com/foo-1.0.tgz'
          desc 'an bar: command-line'
        end
      RUBY

      corrected_source = autocorrect_source(source, "/homebrew-core/Formula/foo.rb")
      expect(corrected_source).to eq(correct_source)
    end
  end
end
