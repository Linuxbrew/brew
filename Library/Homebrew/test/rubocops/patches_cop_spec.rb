require "rubocop"
require "rubocop/rspec/support"
require_relative "../../extend/string"
require_relative "../../rubocops/patches_cop"

describe RuboCop::Cop::FormulaAudit::Patches do
  subject(:cop) { described_class.new }

  context "When auditing legacy patches" do
    it "When there is no legacy patch" do
      source = <<-EOS.undent
        class Foo < Formula
          url 'http://example.com/foo-1.0.tgz'
        end
      EOS
      inspect_source(cop, source)
      expect(cop.offenses).to eq([])
    end

    it "Formula with `def patches`" do
      source = <<-EOS.undent
        class Foo < Formula
          homepage "ftp://example.com/foo"
          url "http://example.com/foo-1.0.tgz"
          def patches
            DATA
          end
        end
      EOS

      expected_offenses = [{  message: "Use the patch DSL instead of defining a 'patches' method",
                              severity: :convention,
                              line: 4,
                              column: 2,
                              source: source }]

      inspect_source(cop, source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "Patch URLs" do
      patch_urls = [
        "https://raw.github.com/mogaal/sendemail",
        "https://mirrors.ustc.edu.cn/macports/trunk/",
        "http://trac.macports.org/export/102865/trunk/dports/mail/uudeview/files/inews.c.patch",
        "http://bugs.debian.org/cgi-bin/bugreport.cgi?msg=5;filename=patch-libunac1.txt;att=1;bug=623340",
        "https://patch-diff.githubusercontent.com/raw/foo/foo-bar/pull/100.patch",
      ]
      patch_urls.each do |patch_url|
        source = <<-EOS.undent
          class Foo < Formula
            homepage "ftp://example.com/foo"
            url "http://example.com/foo-1.0.tgz"
            def patches
              "#{patch_url}"
            end
          end
        EOS

        inspect_source(cop, source)
        if patch_url =~ %r{/raw\.github\.com/}
          expected_offenses = [{  message: "GitHub/Gist patches should specify a revision:\n#{patch_url}",
                                  severity: :convention,
                                  line: 5,
                                  column: 12,
                                  source: source }]
        elsif patch_url =~ %r{macports/trunk}
          expected_offenses = [{  message:  "MacPorts patches should specify a revision instead of trunk:\n#{patch_url}",
                                  severity: :convention,
                                  line: 5,
                                  column: 33,
                                  source: source }]
        elsif patch_url =~ %r{^http://trac\.macports\.org}
          expected_offenses = [{  message:  "Patches from MacPorts Trac should be https://, not http:\n#{patch_url}",
                                  severity: :convention,
                                  line: 5,
                                  column: 5,
                                  source: source }]
        elsif patch_url =~ %r{^http://bugs\.debian\.org}
          expected_offenses = [{  message:  "Patches from Debian should be https://, not http:\n#{patch_url}",
                                  severity: :convention,
                                  line: 5,
                                  column: 5,
                                  source: source }]
        elsif patch_url =~ %r{https?://patch-diff\.githubusercontent\.com/raw/(.+)/(.+)/pull/(.+)\.(?:diff|patch)}
          expected_offenses = [{  message:  "use GitHub pull request URLs:\n"\
                                            "  https://github.com/foo/foo-bar/pull/100.patch\n"\
                                            "Rather than patch-diff:\n"\
                                            "  https://patch-diff.githubusercontent.com/raw/foo/foo-bar/pull/100.patch\n",
                                  severity: :convention,
                                  line: 5,
                                  column: 5,
                                  source: source }]
        end
        expected_offenses.zip([cop.offenses.last]).each do |expected, actual|
          expect_offense(expected, actual)
        end
      end
    end

    it "Formula with nested `def patches`" do
      source = <<-EOS.undent
        class Foo < Formula
          homepage "ftp://example.com/foo"
          url "http://example.com/foo-1.0.tgz"
          def patches
            files = %w[patch-domain_resolver.c patch-colormask.c patch-trafshow.c patch-trafshow.1 patch-configure]
            {
              :p0 =>
              files.collect{|p| "http://trac.macports.org/export/68507/trunk/dports/net/trafshow/files/\#{p}"}
            }
          end
        end
      EOS

      expected_offenses = [{  message: "Use the patch DSL instead of defining a 'patches' method",
                              severity: :convention,
                              line: 4,
                              column: 2,
                              source: source },
                           {  message: "Patches from MacPorts Trac should be https://, not http:\n"\
                                       "http://trac.macports.org/export/68507/trunk/dports/net/trafshow/files/",
                              severity: :convention,
                              line: 8,
                              column: 26,
                              source: source }]

      inspect_source(cop, source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end
  end

  context "When auditing external patches" do
    it "Patch URLs" do
      patch_urls = [
        "https://raw.github.com/mogaal/sendemail",
        "https://mirrors.ustc.edu.cn/macports/trunk/",
        "http://trac.macports.org/export/102865/trunk/dports/mail/uudeview/files/inews.c.patch",
        "http://bugs.debian.org/cgi-bin/bugreport.cgi?msg=5;filename=patch-libunac1.txt;att=1;bug=623340",
        "https://patch-diff.githubusercontent.com/raw/foo/foo-bar/pull/100.patch",
      ]
      patch_urls.each do |patch_url|
        source = <<-EOS.undent
          class Foo < Formula
            homepage "ftp://example.com/foo"
            url "http://example.com/foo-1.0.tgz"
            patch do
              url "#{patch_url}"
              sha256 "63376b8fdd6613a91976106d9376069274191860cd58f039b29ff16de1925621"
            end
          end
        EOS

        inspect_source(cop, source)
        if patch_url =~ %r{/raw\.github\.com/}
          expected_offenses = [{  message: "GitHub/Gist patches should specify a revision:\n#{patch_url}",
                                  severity: :convention,
                                  line: 5,
                                  column: 16,
                                  source: source }]
        elsif patch_url =~ %r{macports/trunk}
          expected_offenses = [{  message:  "MacPorts patches should specify a revision instead of trunk:\n#{patch_url}",
                                  severity: :convention,
                                  line: 5,
                                  column: 37,
                                  source: source }]
        elsif patch_url =~ %r{^http://trac\.macports\.org}
          expected_offenses = [{  message:  "Patches from MacPorts Trac should be https://, not http:\n#{patch_url}",
                                  severity: :convention,
                                  line: 5,
                                  column: 9,
                                  source: source }]
        elsif patch_url =~ %r{^http://bugs\.debian\.org}
          expected_offenses = [{  message:  "Patches from Debian should be https://, not http:\n#{patch_url}",
                                  severity: :convention,
                                  line: 5,
                                  column: 9,
                                  source: source }]
        elsif patch_url =~ %r{https?://patch-diff\.githubusercontent\.com/raw/(.+)/(.+)/pull/(.+)\.(?:diff|patch)}
          expected_offenses = [{  message:  "use GitHub pull request URLs:\n"\
                                            "  https://github.com/foo/foo-bar/pull/100.patch\n"\
                                            "Rather than patch-diff:\n"\
                                            "  https://patch-diff.githubusercontent.com/raw/foo/foo-bar/pull/100.patch\n",
                                  severity: :convention,
                                  line: 5,
                                  column: 9,
                                  source: source }]
        end
        expected_offenses.zip([cop.offenses.last]).each do |expected, actual|
          expect_offense(expected, actual)
        end
      end
    end
  end
end
