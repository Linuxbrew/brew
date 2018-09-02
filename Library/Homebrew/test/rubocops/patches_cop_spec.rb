require "rubocops/patches_cop"

describe RuboCop::Cop::FormulaAudit::Patches do
  subject(:cop) { described_class.new }

  context "When auditing legacy patches" do
    it "When there is no legacy patch" do
      expect_no_offenses(<<~RUBY)
        class Foo < Formula
          url 'https://example.com/foo-1.0.tgz'
        end
      RUBY
    end

    it "Formula with `def patches`" do
      expect_offense(<<~RUBY)
        class Foo < Formula
          homepage "ftp://example.com/foo"
          url "https://example.com/foo-1.0.tgz"
          def patches
          ^^^^^^^^^^^ Use the patch DSL instead of defining a 'patches' method
            DATA
          end
        end
      RUBY
    end

    it "Patch URLs" do
      patch_urls = [
        "https://raw.github.com/mogaal/sendemail",
        "https://mirrors.ustc.edu.cn/macports/trunk/",
        "http://trac.macports.org/export/102865/trunk/dports/mail/uudeview/files/inews.c.patch",
        "http://bugs.debian.org/cgi-bin/bugreport.cgi?msg=5;filename=patch-libunac1.txt;att=1;bug=623340",
        "https://patch-diff.githubusercontent.com/raw/foo/foo-bar/pull/100.patch",
        "https://github.com/dlang/dub/pull/1221.patch",
      ]
      patch_urls.each do |patch_url|
        source = <<~EOS
          class Foo < Formula
            homepage "ftp://example.com/foo"
            url "https://example.com/foo-1.0.tgz"
            def patches
              "#{patch_url}"
            end
          end
        EOS

        inspect_source(source)
        expected_offense = if patch_url =~ %r{/raw\.github\.com/}
          [{ message:
             <<~EOS.chomp,
               GitHub/Gist patches should specify a revision:
               #{patch_url}
             EOS
             severity: :convention,
             line: 5,
             column: 12,
             source: source }]
        elsif patch_url =~ %r{macports/trunk}
          [{ message:
             <<~EOS.chomp,
               MacPorts patches should specify a revision instead of trunk:
               #{patch_url}
             EOS
             severity: :convention,
             line: 5,
             column: 33,
             source: source }]
        elsif patch_url =~ %r{^http://trac\.macports\.org}
          [{ message:
             <<~EOS.chomp,
               Patches from MacPorts Trac should be https://, not http:
               #{patch_url}
             EOS
             severity: :convention,
             line: 5,
             column: 5,
             source: source }]
        elsif patch_url =~ %r{^http://bugs\.debian\.org}
          [{ message:
             <<~EOS.chomp,
               Patches from Debian should be https://, not http:
               #{patch_url}
             EOS
             severity: :convention,
             line: 5,
             column: 5,
             source: source }]
        elsif patch_url =~ %r{https?://patch-diff\.githubusercontent\.com/raw/(.+)/(.+)/pull/(.+)\.(?:diff|patch)}
          [{ message:
             <<~EOS,
               use GitHub pull request URLs:
                 https://github.com/foo/foo-bar/pull/100.patch
               Rather than patch-diff:
                 https://patch-diff.githubusercontent.com/raw/foo/foo-bar/pull/100.patch
             EOS
             severity: :convention,
             line: 5,
             column: 5,
             source: source }]
        elsif patch_url =~ %r{https?://github\.com/.+/.+/(?:commit|pull)/[a-fA-F0-9]*.(?:patch|diff)}
          [{ message:
             <<~EOS,
               GitHub patches should use the full_index parameter:
                 #{patch_url}?full_index=1
             EOS
             severity: :convention,
             line: 5,
             column: 5,
             source: source }]
        end
        expected_offense.zip([cop.offenses.last]).each do |expected, actual|
          expect(actual.message).to eq(expected[:message])
          expect(actual.severity).to eq(expected[:severity])
          expect(actual.line).to eq(expected[:line])
          expect(actual.column).to eq(expected[:column])
        end
      end
    end

    it "Formula with nested `def patches`" do
      source = <<~RUBY
        class Foo < Formula
          homepage "ftp://example.com/foo"
          url "https://example.com/foo-1.0.tgz"
          def patches
            files = %w[patch-domain_resolver.c patch-colormask.c patch-trafshow.c patch-trafshow.1 patch-configure]
            {
              :p0 =>
              files.collect{|p| "http://trac.macports.org/export/68507/trunk/dports/net/trafshow/files/\#{p}"}
            }
          end
        end
      RUBY

      expected_offenses = [{ message: "Use the patch DSL instead of defining a 'patches' method",
                             severity: :convention,
                             line: 4,
                             column: 2,
                             source: source },
                           { message:
                             <<~EOS.chomp,
                               Patches from MacPorts Trac should be https://, not http:
                               http://trac.macports.org/export/68507/trunk/dports/net/trafshow/files/
                             EOS
                             severity: :convention,
                             line: 8,
                             column: 26,
                             source: source }]

      inspect_source(source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect(actual.message).to eq(expected[:message])
        expect(actual.severity).to eq(expected[:severity])
        expect(actual.line).to eq(expected[:line])
        expect(actual.column).to eq(expected[:column])
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
        source = <<~RUBY
          class Foo < Formula
            homepage "ftp://example.com/foo"
            url "https://example.com/foo-1.0.tgz"
            patch do
              url "#{patch_url}"
              sha256 "63376b8fdd6613a91976106d9376069274191860cd58f039b29ff16de1925621"
            end
          end
        RUBY

        inspect_source(source)
        expected_offense = if patch_url =~ %r{/raw\.github\.com/}
          [{ message:
             <<~EOS.chomp,
               GitHub/Gist patches should specify a revision:
               #{patch_url}
             EOS
             severity: :convention,
             line: 5,
             column: 16,
             source: source }]
        elsif patch_url =~ %r{macports/trunk}
          [{ message:
             <<~EOS.chomp,
               MacPorts patches should specify a revision instead of trunk:
               #{patch_url}
             EOS
             severity: :convention,
             line: 5,
             column: 37,
             source: source }]
        elsif patch_url =~ %r{^http://trac\.macports\.org}
          [{ message:
             <<~EOS.chomp,
               Patches from MacPorts Trac should be https://, not http:
               #{patch_url}
             EOS
             severity: :convention,
             line: 5,
             column: 9,
             source: source }]
        elsif patch_url =~ %r{^http://bugs\.debian\.org}
          [{ message:
             <<~EOS.chomp,
               Patches from Debian should be https://, not http:
               #{patch_url}
             EOS
             severity: :convention,
             line: 5,
             column: 9,
             source: source }]
        elsif patch_url =~ %r{https?://patch-diff\.githubusercontent\.com/raw/(.+)/(.+)/pull/(.+)\.(?:diff|patch)}
          [{ message:
             <<~EOS,
               use GitHub pull request URLs:
                 https://github.com/foo/foo-bar/pull/100.patch
               Rather than patch-diff:
                 https://patch-diff.githubusercontent.com/raw/foo/foo-bar/pull/100.patch
             EOS
             severity: :convention,
             line: 5,
             column: 9,
             source: source }]
        end
        expected_offense.zip([cop.offenses.last]).each do |expected, actual|
          expect(actual.message).to eq(expected[:message])
          expect(actual.severity).to eq(expected[:severity])
          expect(actual.line).to eq(expected[:line])
          expect(actual.column).to eq(expected[:column])
        end
      end
    end
  end
end
