require "rubocop"
require "rubocop/rspec/support"
require_relative "../../extend/string"
require_relative "../../rubocops/urls_cop"

describe RuboCop::Cop::FormulaAudit::Urls do
  subject(:cop) { described_class.new }

  context "When auditing urls" do
    it "with offenses" do
      formulas = [{
        "url" => "https://ftpmirror.gnu.org/lightning/lightning-2.1.0.tar.gz",
        "msg" => 'Please use "https://ftp.gnu.org/gnu/lightning/lightning-2.1.0.tar.gz" instead of https://ftpmirror.gnu.org/lightning/lightning-2.1.0.tar.gz.',
        "col" => 2,
      }, {
        "url" => "https://fossies.org/linux/privat/monit-5.23.0.tar.gz",
        "msg" => "Please don't use fossies.org in the url (using as a mirror is fine)",
        "col" => 2,
      }, {
        "url" => "http://tools.ietf.org/tools/rfcmarkup/rfcmarkup-1.119.tgz",
        "msg" => "Please use https:// for http://tools.ietf.org/tools/rfcmarkup/rfcmarkup-1.119.tgz",
        "col" => 2,
      }, {
        "url" => "http://search.mcpan.org/CPAN/authors/id/Z/ZE/ZEFRAM/Perl4-CoreLibs-0.003.tar.gz",
        "msg" => "http://search.mcpan.org/CPAN/authors/id/Z/ZE/ZEFRAM/Perl4-CoreLibs-0.003.tar.gz should be `https://cpan.metacpan.org/authors/id/Z/ZE/ZEFRAM/Perl4-CoreLibs-0.003.tar.gz`",
        "col" => 2,
      }, {
        "url" => "http://ftp.gnome.org/pub/GNOME/binaries/mac/banshee/banshee-2.macosx.intel.dmg",
        "msg" => "http://ftp.gnome.org/pub/GNOME/binaries/mac/banshee/banshee-2.macosx.intel.dmg should be `https://download.gnome.org/binaries/mac/banshee/banshee-2.macosx.intel.dmg`",
        "col" => 2,
      }]

      formulas.each do |formula|
        source = <<-EOS.undent
          class Foo < Formula
            desc "foo"
            url "#{formula["url"]}"
          end
        EOS
        expected_offenses = [{ message: formula["msg"],
                               severity: :convention,
                               line: 3,
                               column: formula["col"],
                               source: source }]

        inspect_source(cop, source)

        expected_offenses.zip(cop.offenses.reverse).each do |expected, actual|
          expect_offense(expected, actual)
        end
      end
    end
  end
end
