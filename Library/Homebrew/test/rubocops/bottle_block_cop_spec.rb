require_relative "../../rubocops/bottle_block_cop"

describe RuboCop::Cop::FormulaAuditStrict::BottleBlock do
  subject(:cop) { described_class.new }

  context "When auditing Bottle Block" do
    it "When there is revision in bottle block" do
      expect_offense(<<~RUBY)
        class Foo < Formula
          url 'http://example.com/foo-1.0.tgz'
          bottle do
            cellar :any
            revision 2
            ^^^^^^^^^^ Use rebuild instead of revision in bottle block
          end
        end
      RUBY
    end
  end

  context "When auditing Bottle Block with auto correct" do
    it "When there is revision in bottle block" do
      source = <<~EOS
        class Foo < Formula
          url 'http://example.com/foo-1.0.tgz'
          bottle do
            cellar :any
            revision 2
          end
        end
      EOS

      corrected_source = <<~EOS
        class Foo < Formula
          url 'http://example.com/foo-1.0.tgz'
          bottle do
            cellar :any
            rebuild 2
          end
        end
      EOS

      new_source = autocorrect_source(source)
      expect(new_source).to eq(corrected_source)
    end
  end
end
