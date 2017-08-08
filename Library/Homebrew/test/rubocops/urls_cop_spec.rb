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
      }, {
        "url" => "git://anonscm.debian.org/users/foo/foostrap.git",
        "msg" => "git://anonscm.debian.org/users/foo/foostrap.git should be `https://anonscm.debian.org/git/users/foo/foostrap.git`",
        "col" => 2,
      }, {
        "url" => "ftp://ftp.mirrorservice.org/foo-1.tar.gz",
        "msg" => "Please use https:// for ftp://ftp.mirrorservice.org/foo-1.tar.gz",
        "col" => 2,
      }, {
        "url" => "ftp://ftp.cpan.org/pub/CPAN/foo-1.tar.gz",
        "msg" => "ftp://ftp.cpan.org/pub/CPAN/foo-1.tar.gz should be `http://search.cpan.org/CPAN/foo-1.tar.gz`",
        "col" => 2,
      }, {
        "url" => "http://sourceforge.net/projects/something/files/Something-1.2.3.dmg",
        "msg" => "Use https://downloads.sourceforge.net to get geolocation (url is http://sourceforge.net/projects/something/files/Something-1.2.3.dmg).",
        "col" => 2,
      }, {
        "url" => "https://downloads.sourceforge.net/project/foo/download",
        "msg" => "Don't use /download in SourceForge urls (url is https://downloads.sourceforge.net/project/foo/download).",
        "col" => 2,
      }, {
        "url" => "https://sourceforge.net/project/foo",
        "msg" => "Use https://downloads.sourceforge.net to get geolocation (url is https://sourceforge.net/project/foo).",
        "col" => 2,
      }, {
        "url" => "http://prdownloads.sourceforge.net/foo/foo-1.tar.gz",
        "msg" => "Don't use prdownloads in SourceForge urls (url is http://prdownloads.sourceforge.net/foo/foo-1.tar.gz).\n" \
                "\tSee: http://librelist.com/browser/homebrew/2011/1/12/prdownloads-is-bad/",
        "col" => 2,
      }, {
        "url" => "http://foo.dl.sourceforge.net/sourceforge/foozip/foozip_1.0.tar.bz2",
        "msg" => "Don't use specific dl mirrors in SourceForge urls (url is http://foo.dl.sourceforge.net/sourceforge/foozip/foozip_1.0.tar.bz2).",
        "col" => 2,
      }, {
        "url" => "http://downloads.sourceforge.net/project/foo/foo/2/foo-2.zip",
        "msg" => "Please use https:// for http://downloads.sourceforge.net/project/foo/foo/2/foo-2.zip",
        "col" => 2,
      }, {
        "url" => "http://http.debian.net/debian/dists/foo/",
        "msg" => "Please use a secure mirror for Debian URLs.\nWe recommend:\n"\
                 "  https://mirrors.ocf.berkeley.edu/debian/dists/foo/\n",
        "col" => 2,
      }, {
        "url" => "http://foo.googlecode.com/files/foo-1.0.zip",
        "msg" => "Please use https:// for http://foo.googlecode.com/files/foo-1.0.zip",
        "col" => 2,
      }, {
        "url" => "git://github.com/foo.git",
        "msg" => "Please use https:// for git://github.com/foo.git",
        "col" => 2,
      }, {
        "url" => "git://gitorious.org/foo/foo5",
        "msg" => "Please use https:// for git://gitorious.org/foo/foo5",
        "col" => 2,
      }, {
        "url" => "http://github.com/foo/foo5.git",
        "msg" => "Please use https:// for http://github.com/foo/foo5.git",
        "col" => 2,
      }, {
        "url" => "https://github.com/foo/foobar/archive/master.zip",
        "msg" => "Use versioned rather than branch tarballs for stable checksums.",
        "col" => 2,
      }, {
        "url" => "https://github.com/foo/bar/tarball/v1.2.3",
        "msg" => "Use /archive/ URLs for GitHub tarballs (url is https://github.com/foo/bar/tarball/v1.2.3).",
        "col" => 2,
      }, {
        "url" => "https://codeload.github.com/foo/bar/tar.gz/v0.1.1",
        "msg" => "Use GitHub archive URLs:\n  https://github.com/foo/bar/archive/v0.1.1.tar.gz\n"\
                 "Rather than codeload:\n  https://codeload.github.com/foo/bar/tar.gz/v0.1.1\n",
        "col" => 2,
      }, {
        "url" => "https://central.maven.org/maven2/com/bar/foo/1.1/foo-1.1.jar",
        "msg" => "https://central.maven.org/maven2/com/bar/foo/1.1/foo-1.1.jar should be `https://search.maven.org/remotecontent?filepath=com/bar/foo/1.1/foo-1.1.jar`",
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

    it "with offenses in stable/devel/head block" do
      formulas = [{
        "url" => "git://github.com/foo.git",
        "msg" => "Please use https:// for git://github.com/foo.git",
        "col" => 4,
      }]
      formulas.each do |formula|
        source = <<-EOS.undent
          class Foo < Formula
            desc "foo"
            url "https://foo.com"

            devel do
              url "#{formula["url"]}",
                  :tag => "v1.0.0-alpha.1",
                  :revision => "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
              version "1.0.0-alpha.1"
            end
          end
        EOS
        expected_offenses = [{ message: formula["msg"],
                               severity: :convention,
                               line: 6,
                               column: formula["col"],
                               source: source }]

        inspect_source(cop, source)

        expected_offenses.zip(cop.offenses.reverse).each do |expected, actual|
          expect_offense(expected, actual)
        end
      end
    end

    it "with duplicate mirror" do
      source = <<-EOS.undent
          class Foo < Formula
            desc "foo"
            url "https://ftpmirror.fnu.org/foo/foo-1.0.tar.gz"
            mirror "https://ftpmirror.fnu.org/foo/foo-1.0.tar.gz"
          end
      EOS

      expected_offenses = [{ message: "URL should not be duplicated as a mirror: https://ftpmirror.fnu.org/foo/foo-1.0.tar.gz",
                             severity: :convention,
                             line: 4,
                             column: 2,
                             source: source }]

      inspect_source(cop, source)

      expected_offenses.zip(cop.offenses.reverse).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end
  end
end

describe RuboCop::Cop::FormulaAuditStrict::PyPiUrls do
  subject(:cop) { described_class.new }

  context "When auditing urls" do
    it "with pypi offenses" do
      formulas = [{
        "url" => "https://pypi.python.org/packages/source/foo/foo-0.1.tar.gz",
        "msg" => "https://pypi.python.org/packages/source/foo/foo-0.1.tar.gz should be `https://files.pythonhosted.org/packages/source/foo/foo-0.1.tar.gz`",
        "col" => 2,
        "corrected_url" =>"https://files.pythonhosted.org/packages/source/foo/foo-0.1.tar.gz",
      }]
      formulas.each do |formula|
        source = <<-EOS.undent
          class Foo < Formula
            desc "foo"
            url "#{formula["url"]}"
          end
        EOS
        corrected_source = <<-EOS.undent
          class Foo < Formula
            desc "foo"
            url "#{formula["corrected_url"]}"
          end
        EOS
        expected_offenses = [{ message: formula["msg"],
                               severity: :convention,
                               line: 3,
                               column: formula["col"],
                               source: source }]

        inspect_source(cop, source)
        # Check for expected offenses
        expected_offenses.zip(cop.offenses.reverse).each do |expected, actual|
          expect_offense(expected, actual)
        end
        # Check for expected auto corrected source
        new_source = autocorrect_source(cop, source)
        expect(new_source).to eq(corrected_source)
      end
    end
  end
end
