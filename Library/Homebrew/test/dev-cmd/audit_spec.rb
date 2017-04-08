require "dev-cmd/audit"
require "formulary"

RSpec::Matchers.alias_matcher :have_data, :be_data
RSpec::Matchers.alias_matcher :have_end, :be_end
RSpec::Matchers.alias_matcher :have_trailing_newline, :be_trailing_newline

describe FormulaText do
  let(:dir) { mktmpdir }

  def formula_text(name, body = nil, options = {})
    path = dir/"#{name}.rb"

    path.write <<-EOS.undent
      class #{Formulary.class_s(name)} < Formula
        #{body}
      end
      #{options[:patch]}
    EOS

    described_class.new(path)
  end

  specify "simple valid Formula" do
    ft = formula_text "valid", <<-EOS.undent
      url "http://www.example.com/valid-1.0.tar.gz"
    EOS

    expect(ft).not_to have_data
    expect(ft).not_to have_end
    expect(ft).to have_trailing_newline

    expect(ft =~ /\burl\b/).to be_truthy
    expect(ft.line_number(/desc/)).to be nil
    expect(ft.line_number(/\burl\b/)).to eq(2)
    expect(ft).to include("Valid")
  end

  specify "#trailing_newline?" do
    ft = formula_text "newline"
    expect(ft).to have_trailing_newline
  end

  specify "#data?" do
    ft = formula_text "data", <<-EOS.undent
      patch :DATA
    EOS

    expect(ft).to have_data
  end

  specify "#end?" do
    ft = formula_text "end", "", patch: "__END__\na patch here"
    expect(ft).to have_end
    expect(ft.without_patch).to eq("class End < Formula\n  \nend")
  end
end

describe FormulaAuditor do
  def formula_auditor(name, text, options = {})
    path = Pathname.new "#{dir}/#{name}.rb"
    path.open("w") do |f|
      f.write text
    end

    described_class.new(Formulary.factory(path), options)
  end

  let(:dir) { mktmpdir }

  describe "#problems" do
    it "is empty by default" do
      fa = formula_auditor "foo", <<-EOS.undent
        class Foo < Formula
          url "http://example.com/foo-1.0.tgz"
        end
      EOS

      expect(fa.problems).to be_empty
    end
  end

  describe "#audit_file" do
    specify "file permissions" do
      allow(File).to receive(:umask).and_return(022)

      fa = formula_auditor "foo", <<-EOS.undent
        class Foo < Formula
          url "http://example.com/foo-1.0.tgz"
        end
      EOS

      path = fa.formula.path
      path.chmod 0400

      fa.audit_file
      expect(fa.problems)
        .to eq(["Incorrect file permissions (400): chmod 644 #{path}"])
    end

    specify "DATA but no __END__" do
      fa = formula_auditor "foo", <<-EOS.undent
        class Foo < Formula
          url "http://example.com/foo-1.0.tgz"
          patch :DATA
        end
      EOS

      fa.audit_file
      expect(fa.problems).to eq(["'DATA' was found, but no '__END__'"])
    end

    specify "__END__ but no DATA" do
      fa = formula_auditor "foo", <<-EOS.undent
        class Foo < Formula
          url "http://example.com/foo-1.0.tgz"
        end
        __END__
        a patch goes here
      EOS

      fa.audit_file
      expect(fa.problems).to eq(["'__END__' was found, but 'DATA' is not used"])
    end

    specify "no trailing newline" do
      fa = formula_auditor "foo", 'class Foo<Formula; url "file:///foo-1.0.tgz";end'

      fa.audit_file
      expect(fa.problems).to eq(["File should end with a newline"])
    end

    specify "no issue" do
      fa = formula_auditor "foo", <<-EOS.undent
        class Foo < Formula
          url "http://example.com/foo-1.0.tgz"
          homepage "http://example.com"
        end
      EOS

      fa.audit_file
      expect(fa.problems).to eq([])
    end
  end

  describe "#audit_class" do
    specify "missing test" do
      fa = formula_auditor "foo", <<-EOS.undent
        class Foo < Formula
          url "http://example.com/foo-1.0.tgz"
        end
      EOS

      fa.audit_class
      expect(fa.problems).to eq([])

      fa = formula_auditor "foo", <<-EOS.undent, strict: true
        class Foo < Formula
          url "http://example.com/foo-1.0.tgz"
        end
      EOS

      fa.audit_class
      expect(fa.problems).to eq(["A `test do` test block should be added"])
    end

    specify "GithubGistFormula", :needs_compat do
      ENV.delete("HOMEBREW_DEVELOPER")

      fa = shutup do
        formula_auditor "foo", <<-EOS.undent
          class Foo < GithubGistFormula
            url "http://example.com/foo-1.0.tgz"
          end
        EOS
      end

      fa.audit_class
      expect(fa.problems)
        .to eq(["GithubGistFormula is deprecated, use Formula instead"])
    end

    specify "ScriptFileFormula", :needs_compat do
      ENV.delete("HOMEBREW_DEVELOPER")

      fa = formula_auditor "foo", <<-EOS.undent
        class Foo < ScriptFileFormula
          url "http://example.com/foo-1.0.tgz"
        end
      EOS

      fa.audit_class
      expect(fa.problems)
        .to eq(["ScriptFileFormula is deprecated, use Formula instead"])
    end

    specify "AmazonWebServicesFormula", :needs_compat do
      ENV.delete("HOMEBREW_DEVELOPER")

      fa = formula_auditor "foo", <<-EOS.undent
        class Foo < AmazonWebServicesFormula
          url "http://example.com/foo-1.0.tgz"
        end
      EOS

      fa.audit_class
      expect(fa.problems)
        .to eq(["AmazonWebServicesFormula is deprecated, use Formula instead"])
    end
  end

  describe "#line_problems" do
    specify "pkgshare" do
      fa = formula_auditor "foo", <<-EOS.undent, strict: true
        class Foo < Formula
          url "http://example.com/foo-1.0.tgz"
        end
      EOS

      fa.line_problems 'ohai "#{share}/foo"', 3
      expect(fa.problems.shift).to eq("Use \#{pkgshare} instead of \#{share}/foo")

      fa.line_problems 'ohai "#{share}/foo/bar"', 3
      expect(fa.problems.shift).to eq("Use \#{pkgshare} instead of \#{share}/foo")

      fa.line_problems 'ohai share/"foo"', 3
      expect(fa.problems.shift).to eq('Use pkgshare instead of (share/"foo")')

      fa.line_problems 'ohai share/"foo/bar"', 3
      expect(fa.problems.shift).to eq('Use pkgshare instead of (share/"foo")')

      fa.line_problems 'ohai "#{share}/foo-bar"', 3
      expect(fa.problems).to eq([])

      fa.line_problems 'ohai share/"foo-bar"', 3
      expect(fa.problems).to eq([])

      fa.line_problems 'ohai share/"bar"', 3
      expect(fa.problems).to eq([])
    end

    # Regression test for https://github.com/Homebrew/legacy-homebrew/pull/48744
    # Formulae with "++" in their name would break various audit regexps:
    #   Error: nested *?+ in regexp: /^libxml++3\s/
    specify "++ in name" do
      fa = formula_auditor "foolibc++", <<-EOS.undent, strict: true
        class Foolibcxx < Formula
          desc "foolibc++ is a test"
          url "http://example.com/foo-1.0.tgz"
        end
      EOS

      fa.line_problems 'ohai "#{share}/foolibc++"', 3
      expect(fa.problems.shift)
        .to eq("Use \#{pkgshare} instead of \#{share}/foolibc++")

      fa.line_problems 'ohai share/"foolibc++"', 3
      expect(fa.problems.shift)
        .to eq('Use pkgshare instead of (share/"foolibc++")')
    end

    specify "no space in class inheritance" do
      fa = formula_auditor "foo", <<-EOS.undent
        class Foo<Formula
          url '/foo-1.0.tgz'
        end
      EOS

      fa.line_problems "class Foo<Formula", 1
      expect(fa.problems.shift)
        .to eq("Use a space in class inheritance: class Foo < Formula")
    end

    specify "default template" do
      fa = formula_auditor "foo", "class Foo < Formula; url '/foo-1.0.tgz'; end"

      fa.line_problems '# system "cmake", ".", *std_cmake_args', 3
      expect(fa.problems.shift).to eq("Commented cmake call found")

      fa.line_problems "# PLEASE REMOVE", 3
      expect(fa.problems.shift).to eq("Please remove default template comments")
    end
  end

  describe "#audit_github_repository" do
    specify "#audit_github_repository when HOMEBREW_NO_GITHUB_API is set" do
      ENV["HOMEBREW_NO_GITHUB_API"] = "1"

      fa = formula_auditor "foo", <<-EOS.undent, strict: true, online: true
        class Foo < Formula
          homepage "https://github.com/example/example"
          url "http://example.com/foo-1.0.tgz"
        end
      EOS

      fa.audit_github_repository
      expect(fa.problems).to eq([])
    end
  end

  specify "#audit_caveats" do
    fa = formula_auditor "foo", <<-EOS.undent
      class Foo < Formula
        homepage "http://example.com/foo"
        url "http://example.com/foo-1.0.tgz"

        def caveats
          "setuid"
        end
      end
    EOS

    fa.audit_caveats
    expect(fa.problems)
      .to eq(["Don't recommend setuid in the caveats, suggest sudo instead."])
  end

  describe "#audit_homepage" do
    specify "homepage URLs" do
      fa = formula_auditor "foo", <<-EOS.undent, online: true
        class Foo < Formula
          homepage "ftp://example.com/foo"
          url "http://example.com/foo-1.0.tgz"
        end
      EOS

      fa.audit_homepage
      expect(fa.problems)
        .to eq(["The homepage should start with http or https (URL is #{fa.formula.homepage})."])

      formula_homepages = {
        "bar" => "http://www.freedesktop.org/wiki/bar",
        "baz" => "http://www.freedesktop.org/wiki/Software/baz",
        "qux" => "https://code.google.com/p/qux",
        "quux" => "http://github.com/quux",
        "corge" => "http://savannah.nongnu.org/corge",
        "grault" => "http://grault.github.io/",
        "garply" => "http://www.gnome.org/garply",
        "sf1" => "http://foo.sourceforge.net/",
        "sf2" => "http://foo.sourceforge.net",
        "sf3" => "http://foo.sf.net/",
        "sf4" => "http://foo.sourceforge.io/",
        "waldo" => "http://www.gnu.org/waldo",
      }

      formula_homepages.each do |name, homepage|
        fa = formula_auditor name, <<-EOS.undent
          class #{Formulary.class_s(name)} < Formula
            homepage "#{homepage}"
            url "http://example.com/#{name}-1.0.tgz"
          end
        EOS

        fa.audit_homepage
        if homepage =~ %r{http:\/\/www\.freedesktop\.org}
          if homepage =~ /Software/
            expect(fa.problems.first).to match(
              "#{homepage} should be styled " \
              "`https://wiki.freedesktop.org/www/Software/project_name`",
            )
          else
            expect(fa.problems.first).to match(
              "#{homepage} should be styled " \
              "`https://wiki.freedesktop.org/project_name`",
            )
          end
        elsif homepage =~ %r{https:\/\/code\.google\.com}
          expect(fa.problems.first)
            .to match("#{homepage} should end with a slash")
        elsif homepage =~ /foo\.(sf|sourceforge)\.net/
          expect(fa.problems.first)
            .to match("#{homepage} should be `https://foo.sourceforge.io/`")
        else
          expect(fa.problems.first)
            .to match("Please use https:// for #{homepage}")
        end
      end
    end

    specify "missing homepage" do
      fa = formula_auditor "foo", <<-EOS.undent, online: true
        class Foo < Formula
          url "http://example.com/foo-1.0.tgz"
        end
      EOS

      fa.audit_homepage
      expect(fa.problems.first).to match("Formula should have a homepage.")
    end
  end

  describe "#audit_text" do
    specify "xcodebuild suggests symroot" do
      fa = formula_auditor "foo", <<-EOS.undent
        class Foo < Formula
          url "http://example.com/foo-1.0.tgz"
          homepage "http://example.com"

          def install
            xcodebuild "-project", "meow.xcodeproject"
          end
        end
      EOS

      fa.audit_text
      expect(fa.problems.first)
        .to match('xcodebuild should be passed an explicit "SYMROOT"')
    end

    specify "bare xcodebuild also suggests symroot" do
      fa = formula_auditor "foo", <<-EOS.undent
        class Foo < Formula
          url "http://example.com/foo-1.0.tgz"
          homepage "http://example.com"

          def install
            xcodebuild
          end
        end
      EOS

      fa.audit_text
      expect(fa.problems.first)
        .to match('xcodebuild should be passed an explicit "SYMROOT"')
    end
  end
end
