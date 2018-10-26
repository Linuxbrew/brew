require "rubocops/conflicts"

describe RuboCop::Cop::FormulaAudit::Conflicts do
  subject(:cop) { described_class.new }

  context "When auditing formula for conflicts with" do
    it "multiple conflicts_with" do
      expect_offense(<<~RUBY, "/homebrew-core/Formula/foo@2.0.rb")
        class FooAT20 < Formula
          url 'https://example.com/foo-2.0.tgz'
          conflicts_with "mysql", "mariadb", "percona-server",
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Versioned formulae should not use `conflicts_with`. Use `keg_only :versioned_formula` instead.
                           :because => "both install plugins"
        end
      RUBY
    end

    it "no conflicts_with" do
      expect_no_offenses(<<~RUBY, "/homebrew-core/Formula/foo@2.0.rb")
        class FooAT20 < Formula
          url 'https://example.com/foo-2.0.tgz'
          desc 'Bar'
        end
      RUBY
    end
  end
end
