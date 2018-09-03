describe Tap do
  alias_matcher :have_formula_file, :be_formula_file
  alias_matcher :have_custom_remote, :be_custom_remote

  subject { described_class.new("Homebrew", "foo") }

  let(:path) { Tap::TAP_DIRECTORY/"homebrew/homebrew-foo" }
  let(:formula_file) { path/"Formula/foo.rb" }
  let(:alias_file) { path/"Aliases/bar" }
  let(:cmd_file) { path/"cmd/brew-tap-cmd.rb" }
  let(:manpage_file) { path/"manpages/brew-tap-cmd.1" }
  let(:bash_completion_file) { path/"completions/bash/brew-tap-cmd" }
  let(:zsh_completion_file) { path/"completions/zsh/_brew-tap-cmd" }
  let(:fish_completion_file) { path/"completions/fish/brew-tap-cmd.fish" }

  before do
    path.mkpath
  end

  def setup_tap_files
    formula_file.write <<~RUBY
      class Foo < Formula
        url "https://example.com/foo-1.0.tar.gz"
      end
    RUBY

    alias_file.parent.mkpath
    ln_s formula_file, alias_file

    (path/"formula_renames.json").write <<~JSON
      { "oldname": "foo" }
    JSON

    (path/"tap_migrations.json").write <<~JSON
      { "removed-formula": "homebrew/foo" }
    JSON

    [
      cmd_file,
      manpage_file,
      bash_completion_file,
      zsh_completion_file,
      fish_completion_file,
    ].each do |f|
      f.parent.mkpath
      touch f
    end

    chmod 0755, cmd_file
  end

  def setup_git_repo
    path.cd do
      system "git", "init"
      system "git", "remote", "add", "origin", "https://github.com/Homebrew/homebrew-foo"
      system "git", "add", "--all"
      system "git", "commit", "-m", "init"
    end
  end

  specify "::fetch" do
    begin
      expect(described_class.fetch("Homebrew", "core")).to be_kind_of(CoreTap)
      expect(described_class.fetch("Homebrew", "homebrew")).to be_kind_of(CoreTap)
      tap = described_class.fetch("Homebrew", "foo")
      expect(tap).to be_kind_of(described_class)
      expect(tap.name).to eq("homebrew/foo")

      expect {
        described_class.fetch("foo")
      }.to raise_error(/Invalid tap name/)

      expect {
        described_class.fetch("homebrew/homebrew/bar")
      }.to raise_error(/Invalid tap name/)

      expect {
        described_class.fetch("homebrew", "homebrew/baz")
      }.to raise_error(/Invalid tap name/)
    ensure
      described_class.clear_cache
    end
  end

  describe "::from_path" do
    let(:tap) { described_class.fetch("Homebrew", "core") }
    let(:path) { tap.path }
    let(:formula_path) { path/"Formula/formula.rb" }

    it "returns the Tap for a Formula path" do
      expect(described_class.from_path(formula_path)).to eq tap
    end

    it "returns the Tap when given its exact path" do
      expect(described_class.from_path(path)).to eq tap
    end
  end

  specify "::names" do
    expect(described_class.names.sort).to eq(["homebrew/core", "homebrew/foo"])
  end

  specify "attributes" do
    expect(subject.user).to eq("Homebrew")
    expect(subject.repo).to eq("foo")
    expect(subject.name).to eq("homebrew/foo")
    expect(subject.path).to eq(path)
    expect(subject).to be_installed
    expect(subject).to be_official
    expect(subject).not_to be_a_core_tap
  end

  specify "#issues_url" do
    begin
      t = described_class.new("someone", "foo")
      path = Tap::TAP_DIRECTORY/"someone/homebrew-foo"
      path.mkpath
      cd path do
        system "git", "init"
        system "git", "remote", "add", "origin",
          "https://github.com/someone/homebrew-foo"
      end
      expect(t.issues_url).to eq("https://github.com/someone/homebrew-foo/issues")
      expect(subject.issues_url).to eq("https://github.com/Homebrew/homebrew-foo/issues")

      (Tap::TAP_DIRECTORY/"someone/homebrew-no-git").mkpath
      expect(described_class.new("someone", "no-git").issues_url).to be nil
    ensure
      path.parent.rmtree
    end
  end

  specify "files" do
    setup_tap_files

    expect(subject.formula_files).to eq([formula_file])
    expect(subject.formula_names).to eq(["homebrew/foo/foo"])
    expect(subject.alias_files).to eq([alias_file])
    expect(subject.aliases).to eq(["homebrew/foo/bar"])
    expect(subject.alias_table).to eq("homebrew/foo/bar" => "homebrew/foo/foo")
    expect(subject.alias_reverse_table).to eq("homebrew/foo/foo" => ["homebrew/foo/bar"])
    expect(subject.formula_renames).to eq("oldname" => "foo")
    expect(subject.tap_migrations).to eq("removed-formula" => "homebrew/foo")
    expect(subject.command_files).to eq([cmd_file])
    expect(subject.to_hash).to be_kind_of(Hash)
    expect(subject).to have_formula_file(formula_file)
    expect(subject).to have_formula_file("Formula/foo.rb")
    expect(subject).not_to have_formula_file("bar.rb")
    expect(subject).not_to have_formula_file("Formula/baz.sh")
  end

  describe "#remote" do
    it "returns the remote URL" do
      setup_git_repo

      expect(subject.remote).to eq("https://github.com/Homebrew/homebrew-foo")
      expect { described_class.new("Homebrew", "bar").remote }.to raise_error(TapUnavailableError)
      expect(subject).not_to have_custom_remote

      services_tap = described_class.new("Homebrew", "services")
      services_tap.path.mkpath
      services_tap.path.cd do
        system "git", "init"
        system "git", "remote", "add", "origin", "https://github.com/Homebrew/homebrew-services"
      end
      expect(services_tap).not_to be_private
    end

    it "returns nil if the Tap is not a Git repo" do
      expect(subject.remote).to be nil
    end

    it "returns nil if Git is not available" do
      setup_git_repo
      allow(Utils).to receive(:git_available?).and_return(false)
      expect(subject.remote).to be nil
    end
  end

  specify "Git variant" do
    touch path/"README"
    setup_git_repo

    expect(subject.git_head).to eq("0453e16c8e3fac73104da50927a86221ca0740c2")
    expect(subject.git_short_head).to eq("0453")
    expect(subject.git_last_commit).to match(/\A\d+ .+ ago\Z/)
    expect(subject.git_last_commit_date).to eq("2017-01-22")
  end

  specify "#private?" do
    skip "HOMEBREW_GITHUB_API_TOKEN is required" unless GitHub.api_credentials
    expect(subject).to be_private
  end

  describe "#install" do
    it "raises an error when the Tap is already tapped" do
      setup_git_repo
      already_tapped_tap = described_class.new("Homebrew", "foo")
      expect(already_tapped_tap).to be_installed
      expect { already_tapped_tap.install }.to raise_error(TapAlreadyTappedError)
    end

    it "raises an error when the Tap is already tapped with the right remote" do
      setup_git_repo
      already_tapped_tap = described_class.new("Homebrew", "foo")
      expect(already_tapped_tap).to be_installed
      right_remote = subject.remote
      expect { already_tapped_tap.install clone_target: right_remote }.to raise_error(TapAlreadyTappedError)
    end

    it "raises an error when the remote doesn't match" do
      setup_git_repo
      already_tapped_tap = described_class.new("Homebrew", "foo")
      touch subject.path/".git/shallow"
      expect(already_tapped_tap).to be_installed
      wrong_remote = "#{subject.remote}-oops"
      expect {
        already_tapped_tap.install clone_target: wrong_remote, full_clone: true
      }.to raise_error(TapRemoteMismatchError)
    end

    it "raises an error when the Tap is already unshallow" do
      setup_git_repo
      already_tapped_tap = described_class.new("Homebrew", "foo")
      expect { already_tapped_tap.install full_clone: true }.to raise_error(TapAlreadyUnshallowError)
    end

    describe "force_auto_update" do
      before do
        setup_git_repo
      end

      let(:already_tapped_tap) { described_class.new("Homebrew", "foo") }

      it "defaults to nil" do
        expect(already_tapped_tap).to be_installed
        expect(already_tapped_tap.config["forceautoupdate"]).to be_nil
      end

      it "enables forced auto-updates when true" do
        expect(already_tapped_tap).to be_installed
        already_tapped_tap.install force_auto_update: true
        expect(already_tapped_tap.config["forceautoupdate"]).to eq("true")
      end

      it "disables forced auto-updates when false" do
        expect(already_tapped_tap).to be_installed
        already_tapped_tap.install force_auto_update: false
        expect(already_tapped_tap.config["forceautoupdate"]).to eq("false")
      end
    end

    specify "Git error" do
      tap = described_class.new("user", "repo")

      expect {
        tap.install clone_target: "file:///not/existed/remote/url"
      }.to raise_error(ErrorDuringExecution)

      expect(tap).not_to be_installed
      expect(Tap::TAP_DIRECTORY/"user").not_to exist
    end
  end

  describe "#uninstall" do
    it "raises an error if the Tap is not available" do
      tap = described_class.new("Homebrew", "bar")
      expect { tap.uninstall }.to raise_error(TapUnavailableError)
    end
  end

  specify "#install and #uninstall" do
    begin
      setup_tap_files
      setup_git_repo

      tap = described_class.new("Homebrew", "bar")

      tap.install clone_target: subject.path/".git"

      expect(tap).to be_installed
      expect(HOMEBREW_PREFIX/"share/man/man1/brew-tap-cmd.1").to be_a_file
      expect(HOMEBREW_PREFIX/"etc/bash_completion.d/brew-tap-cmd").to be_a_file
      expect(HOMEBREW_PREFIX/"share/zsh/site-functions/_brew-tap-cmd").to be_a_file
      expect(HOMEBREW_PREFIX/"share/fish/vendor_completions.d/brew-tap-cmd.fish").to be_a_file
      tap.uninstall

      expect(tap).not_to be_installed
      expect(HOMEBREW_PREFIX/"share/man/man1/brew-tap-cmd.1").not_to exist
      expect(HOMEBREW_PREFIX/"share/man/man1").not_to exist
      expect(HOMEBREW_PREFIX/"etc/bash_completion.d/brew-tap-cmd").not_to exist
      expect(HOMEBREW_PREFIX/"share/zsh/site-functions/_brew-tap-cmd").not_to exist
      expect(HOMEBREW_PREFIX/"share/fish/vendor_completions.d/brew-tap-cmd.fish").not_to exist
    ensure
      (HOMEBREW_PREFIX/"etc").rmtree if (HOMEBREW_PREFIX/"etc").exist?
      (HOMEBREW_PREFIX/"share").rmtree if (HOMEBREW_PREFIX/"share").exist?
    end
  end

  specify "#link_completions_and_manpages" do
    begin
      setup_tap_files
      setup_git_repo
      tap = described_class.new("Homebrew", "baz")
      tap.install clone_target: subject.path/".git"
      (HOMEBREW_PREFIX/"share/man/man1/brew-tap-cmd.1").delete
      (HOMEBREW_PREFIX/"etc/bash_completion.d/brew-tap-cmd").delete
      (HOMEBREW_PREFIX/"share/zsh/site-functions/_brew-tap-cmd").delete
      (HOMEBREW_PREFIX/"share/fish/vendor_completions.d/brew-tap-cmd.fish").delete
      tap.link_completions_and_manpages
      expect(HOMEBREW_PREFIX/"share/man/man1/brew-tap-cmd.1").to be_a_file
      expect(HOMEBREW_PREFIX/"etc/bash_completion.d/brew-tap-cmd").to be_a_file
      expect(HOMEBREW_PREFIX/"share/zsh/site-functions/_brew-tap-cmd").to be_a_file
      expect(HOMEBREW_PREFIX/"share/fish/vendor_completions.d/brew-tap-cmd.fish").to be_a_file
      tap.uninstall
    ensure
      (HOMEBREW_PREFIX/"etc").rmtree if (HOMEBREW_PREFIX/"etc").exist?
      (HOMEBREW_PREFIX/"share").rmtree if (HOMEBREW_PREFIX/"share").exist?
    end
  end

  specify "#pin and #unpin" do
    expect(subject).not_to be_pinned
    expect { subject.unpin }.to raise_error(TapPinStatusError)
    subject.pin
    expect(subject).to be_pinned
    expect { subject.pin }.to raise_error(TapPinStatusError)
    subject.unpin
    expect(subject).not_to be_pinned
  end

  specify "#config" do
    setup_git_repo

    expect(subject.config["foo"]).to be nil
    subject.config["foo"] = "bar"
    expect(subject.config["foo"]).to eq("bar")
    subject.config["foo"] = nil
    expect(subject.config["foo"]).to be nil
  end

  describe "#each" do
    it "returns an enumerator if no block is passed" do
      expect(described_class.each).to be_an_instance_of(Enumerator)
    end
  end
end

describe CoreTap do
  specify "attributes" do
    expect(subject.user).to eq("Homebrew")
    expect(subject.repo).to eq("core")
    expect(subject.name).to eq("homebrew/core")
    expect(subject.command_files).to eq([])
    expect(subject).to be_installed
    expect(subject).not_to be_pinned
    expect(subject).to be_official
    expect(subject).to be_a_core_tap
  end

  specify "forbidden operations" do
    expect { subject.uninstall }.to raise_error(RuntimeError)
    expect { subject.pin }.to raise_error(RuntimeError)
    expect { subject.unpin }.to raise_error(RuntimeError)
  end

  specify "files" do
    formula_file = subject.formula_dir/"foo.rb"
    formula_file.write <<~RUBY
      class Foo < Formula
        url "https://example.com/foo-1.0.tar.gz"
      end
    RUBY

    alias_file = subject.alias_dir/"bar"
    alias_file.parent.mkpath
    ln_s formula_file, alias_file

    expect(subject.formula_files).to eq([formula_file])
    expect(subject.formula_names).to eq(["foo"])
    expect(subject.alias_files).to eq([alias_file])
    expect(subject.aliases).to eq(["bar"])
    expect(subject.alias_table).to eq("bar" => "foo")
    expect(subject.alias_reverse_table).to eq("foo" => ["bar"])
  end
end
