require "dev-cmd/audit"
require "formulary"

module Count
  def self.increment
    @count ||= 0
    @count  += 1
  end
end

describe FormulaText do
  alias_matcher :have_data, :be_data
  alias_matcher :have_end, :be_end
  alias_matcher :have_trailing_newline, :be_trailing_newline

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

      fa = formula_auditor "foo", <<-EOS.undent
        class Foo < GithubGistFormula
          url "http://example.com/foo-1.0.tgz"
        end
      EOS

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

  describe "#audit_keg_only_style" do
    specify "keg_only_needs_downcasing" do
      fa = formula_auditor "foo", <<-EOS.undent, strict: true
        class Foo < Formula
          url "http://example.com/foo-1.0.tgz"

          keg_only "Because why not"
        end
      EOS

      fa.audit_keg_only_style
      expect(fa.problems)
        .to eq(["'Because' from the keg_only reason should be 'because'.\n"])
    end

    specify "keg_only_redundant_period" do
      fa = formula_auditor "foo", <<-EOS.undent, strict: true
        class Foo < Formula
          url "http://example.com/foo-1.0.tgz"

          keg_only "because this line ends in a period."
        end
      EOS

      fa.audit_keg_only_style
      expect(fa.problems)
        .to eq(["keg_only reason should not end with a period."])
    end

    specify "keg_only_handles_block_correctly" do
      fa = formula_auditor "foo", <<-EOS.undent, strict: true
        class Foo < Formula
          url "http://example.com/foo-1.0.tgz"

          keg_only <<-EOF.undent
            this line starts with a lowercase word.

            This line does not but that shouldn't be a
            problem
          EOF
        end
      EOS

      fa.audit_keg_only_style
      expect(fa.problems)
        .to eq([])
    end

    specify "keg_only_handles_whitelist_correctly" do
      fa = formula_auditor "foo", <<-EOS.undent, strict: true
        class Foo < Formula
          url "http://example.com/foo-1.0.tgz"

          keg_only "Apple ships foo in the CLT package"
        end
      EOS

      fa.audit_keg_only_style
      expect(fa.problems)
        .to eq([])
    end
  end

  describe "#audit_revision_and_version_scheme" do
    let(:origin_tap_path) { Tap::TAP_DIRECTORY/"homebrew/homebrew-foo" }
    let(:formula_subpath) { "Formula/foo#{@foo_version}.rb" }
    let(:origin_formula_path) { origin_tap_path/formula_subpath }
    let(:tap_path) { Tap::TAP_DIRECTORY/"homebrew/homebrew-bar" }
    let(:formula_path) { tap_path/formula_subpath }

    before(:each) do
      @foo_version = Count.increment

      origin_formula_path.write <<-EOS.undent
        class Foo#{@foo_version} < Formula
          url "https://example.com/foo-1.0.tar.gz"
          revision 2
          version_scheme 1
        end
      EOS

      origin_tap_path.mkpath
      origin_tap_path.cd do
        system "git", "init"
        system "git", "add", "--all"
        system "git", "commit", "-m", "init"
      end

      tap_path.mkpath
      tap_path.cd do
        system "git", "clone", origin_tap_path, "."
      end
    end

    subject do
      fa = described_class.new(Formulary.factory(formula_path))
      fa.audit_revision_and_version_scheme
      fa.problems.first
    end

    def formula_gsub(before, after = "")
      text = formula_path.read
      text.gsub! before, after
      formula_path.unlink
      formula_path.write text
    end

    def formula_gsub_commit(before, after = "")
      text = origin_formula_path.read
      text.gsub!(before, after)
      origin_formula_path.unlink
      origin_formula_path.write text

      origin_tap_path.cd do
        system "git", "commit", "-am", "commit"
      end

      tap_path.cd do
        system "git", "fetch"
        system "git", "reset", "--hard", "origin/master"
      end
    end

    context "revisions" do
      context "should not be removed when first committed above 0" do
        it { is_expected.to be_nil }
      end

      context "should not decrease with the same version" do
        before { formula_gsub_commit "revision 2", "revision 1" }

        it { is_expected.to match("revision should not decrease (from 2 to 1)") }
      end

      context "should not be removed with the same version" do
        before { formula_gsub_commit "revision 2" }

        it { is_expected.to match("revision should not decrease (from 2 to 0)") }
      end

      context "should not decrease with the same, uncommitted version" do
        before { formula_gsub "revision 2", "revision 1" }

        it { is_expected.to match("revision should not decrease (from 2 to 1)") }
      end

      context "should be removed with a newer version" do
        before { formula_gsub_commit "foo-1.0.tar.gz", "foo-1.1.tar.gz" }

        it { is_expected.to match("'revision 2' should be removed") }
      end

      context "should not warn on an newer version revision removal" do
        before do
          formula_gsub_commit "revision 2", ""
          formula_gsub_commit "foo-1.0.tar.gz", "foo-1.1.tar.gz"
        end

        it { is_expected.to be_nil }
      end

      context "should only increment by 1 with an uncommitted version" do
        before do
          formula_gsub "foo-1.0.tar.gz", "foo-1.1.tar.gz"
          formula_gsub "revision 2", "revision 4"
        end

        it { is_expected.to match("revisions should only increment by 1") }
      end

      context "should not warn on past increment by more than 1" do
        before do
          formula_gsub_commit "revision 2", "# no revision"
          formula_gsub_commit "foo-1.0.tar.gz", "foo-1.1.tar.gz"
          formula_gsub_commit "# no revision", "revision 3"
        end

        it { is_expected.to be_nil }
      end
    end

    context "version_schemes" do
      context "should not decrease with the same version" do
        before { formula_gsub_commit "version_scheme 1" }

        it { is_expected.to match("version_scheme should not decrease (from 1 to 0)") }
      end

      context "should not decrease with a new version" do
        before do
          formula_gsub_commit "foo-1.0.tar.gz", "foo-1.1.tar.gz"
          formula_gsub_commit "version_scheme 1", ""
          formula_gsub_commit "revision 2", ""
        end

        it { is_expected.to match("version_scheme should not decrease (from 1 to 0)") }
      end

      context "should only increment by 1" do
        before do
          formula_gsub_commit "version_scheme 1", "# no version_scheme"
          formula_gsub_commit "foo-1.0.tar.gz", "foo-1.1.tar.gz"
          formula_gsub_commit "revision 2", ""
          formula_gsub_commit "# no version_scheme", "version_scheme 3"
        end

        it { is_expected.to match("version_schemes should only increment by 1") }
      end
    end

    context "versions" do
      context "uncommitted should not decrease" do
        before { formula_gsub "foo-1.0.tar.gz", "foo-0.9.tar.gz" }

        it { is_expected.to match("stable version should not decrease (from 1.0 to 0.9)") }
      end

      context "committed can decrease" do
        before do
          formula_gsub_commit "revision 2"
          formula_gsub_commit "foo-1.0.tar.gz", "foo-0.9.tar.gz"
        end

        it { is_expected.to be_nil }
      end

      context "can decrease with version_scheme increased" do
        before do
          formula_gsub "revision 2"
          formula_gsub "foo-1.0.tar.gz", "foo-0.9.tar.gz"
          formula_gsub "version_scheme 1", "version_scheme 2"
        end

        it { is_expected.to be_nil }
      end
    end
  end
end
