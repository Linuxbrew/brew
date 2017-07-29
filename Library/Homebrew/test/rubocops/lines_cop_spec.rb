require "rubocop"
require "rubocop/rspec/support"
require_relative "../../extend/string"
require_relative "../../rubocops/lines_cop"

describe RuboCop::Cop::FormulaAudit::Lines do
  subject(:cop) { described_class.new }

  context "When auditing lines" do
    it "with correctable deprecated dependencies" do
      formulae = [{
        "dependency" => :automake,
        "correct"    => "automake",
      }, {
        "dependency" => :autoconf,
        "correct"    => "autoconf",
      }, {
        "dependency" => :libtool,
        "correct"    => "libtool",
      }, {
        "dependency" => :apr,
        "correct"    => "apr-util",
      }, {
        "dependency" => :tex,
      }]

      formulae.each do |formula|
        source = <<-EOS.undent
        class Foo < Formula
          url 'http://example.com/foo-1.0.tgz'
          depends_on :#{formula["dependency"]}
        end
        EOS
        if formula.key?("correct")
          offense = ":#{formula["dependency"]} is deprecated. Usage should be \"#{formula["correct"]}\""
        else
          offense = ":#{formula["dependency"]} is deprecated"
        end
        expected_offenses = [{  message: offense,
                                severity: :convention,
                                line: 3,
                                column: 2,
                                source: source }]

        inspect_source(cop, source)

        expected_offenses.zip(cop.offenses.reverse).each do |expected, actual|
          expect_offense(expected, actual)
        end
      end
    end
  end
end
