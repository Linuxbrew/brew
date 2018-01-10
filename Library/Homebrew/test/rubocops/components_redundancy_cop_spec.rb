require_relative "../../rubocops/components_redundancy_cop"

describe RuboCop::Cop::FormulaAuditStrict::ComponentsRedundancy do
  subject(:cop) { described_class.new }

  context "When auditing formula components common errors" do
    it "When url outside stable block" do
      expect_offense(<<~RUBY)
        class Foo < Formula
          url "http://example.com/foo-1.0.tgz"
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ `url` should be put inside `stable` block
          stable do
            # stuff
          end
        end
      RUBY
    end

    it "When both `head` and `head do` are present" do
      expect_offense(<<~RUBY)
        class Foo < Formula
          head "http://example.com/foo.git"
          head do
          ^^^^^^^ `head` and `head do` should not be simultaneously present
            # stuff
          end
        end
      RUBY
    end

    it "When both `bottle :modifier` and `bottle do` are present" do
      expect_offense(<<~RUBY)
        class Foo < Formula
          url "http://example.com/foo-1.0.tgz"
          bottle do
          ^^^^^^^^^ `bottle :modifier` and `bottle do` should not be simultaneously present
            # bottles go here
          end
          bottle :unneeded
        end
      RUBY
    end
  end
end
