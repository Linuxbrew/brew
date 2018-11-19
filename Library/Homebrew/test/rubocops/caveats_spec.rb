require "rubocops/caveats"

describe RuboCop::Cop::FormulaAudit::Caveats do
  subject(:cop) { described_class.new }

  context "When auditing caveats" do
    it "When there is setuid mentioned in caveats" do
      expect_offense(<<~RUBY)
        class Foo < Formula
          homepage "https://example.com/foo"
          url "https://example.com/foo-1.0.tgz"
           def caveats
            "setuid"
             ^^^^^^ Don\'t recommend setuid in the caveats, suggest sudo instead.
          end
        end
      RUBY
    end
  end
end
