require "formula"
require "formula_installer"
require "keg"
require "tab"
require "test/support/fixtures/testball"
require "test/support/fixtures/testball_bottle"
require "test/support/fixtures/failball"

describe FormulaInstaller do
  define_negated_matcher :need_bottle, :be_bottle_unneeded
  alias_matcher :have_disabled_bottle, :be_bottle_disabled

  matcher :be_poured_from_bottle do
    match(&:poured_from_bottle)
  end

  def temporary_install(formula)
    expect(formula).not_to be_installed

    installer = described_class.new(formula)

    installer.install

    keg = Keg.new(formula.prefix)

    expect(formula).to be_installed

    begin
      Tab.clear_cache
      expect(Tab.for_keg(keg)).not_to be_poured_from_bottle

      yield formula if block_given?
    ensure
      Tab.clear_cache
      keg.unlink
      keg.uninstall
      formula.clear_cache
      # there will be log files when sandbox is enable.
      formula.logs.rmtree if formula.logs.directory?
    end

    expect(keg).not_to exist
    expect(formula).not_to be_installed
  end

  specify "basic installation" do
    ARGV << "--with-invalid_flag" # added to ensure it doesn't fail install

    temporary_install(Testball.new) do |f|
      # Test that things made it into the Keg
      expect(f.prefix/"readme").to exist

      expect(f.bin).to be_a_directory
      expect(f.bin.children.count).to eq(3)

      expect(f.libexec).to be_a_directory
      expect(f.libexec.children.count).to eq(1)

      expect(f.prefix/"main.c").not_to exist
      expect(f.prefix/"license").not_to exist

      # Test that things make it into the Cellar
      keg = Keg.new f.prefix
      keg.link

      bin = HOMEBREW_PREFIX/"bin"
      expect(bin).to be_a_directory
      expect(bin.children.count).to eq(3)
      expect(f.prefix/".brew/testball.rb").to be_readable
    end
  end

  specify "Formula installation with unneeded bottle" do
    allow(DevelopmentTools).to receive(:installed?).and_return(false)

    formula = Testball.new
    allow(formula).to receive(:bottle_unneeded?).and_return(true)
    allow(formula).to receive(:bottle_disabled?).and_return(true)

    expect(formula).not_to be_bottled
    expect(formula).not_to need_bottle
    expect(formula).to have_disabled_bottle

    temporary_install(formula) do |f|
      expect(f).to be_installed
    end
  end

  specify "Formula is not poured from bottle when compiler specified" do
    expect(ARGV.cc).to be nil

    cc_arg = "--cc=clang"
    ARGV << cc_arg

    temporary_install(TestballBottle.new) do |f|
      tab = Tab.for_formula(f)
      expect(tab.compiler).to eq("clang")
    end
  end

  specify "check installation sanity pinned dependency" do
    dep_name = "dependency"
    dep_path = CoreTap.new.formula_dir/"#{dep_name}.rb"
    dep_path.write <<~RUBY
      class #{Formulary.class_s(dep_name)} < Formula
        url "foo"
        version "0.2"
      end
    RUBY

    Formulary.cache.delete(dep_path)
    dependency = Formulary.factory(dep_name)

    dependent = formula do
      url "foo"
      version "0.5"
      depends_on dependency.name.to_s
    end

    (dependency.prefix("0.1")/"bin"/"a").mkpath
    HOMEBREW_PINNED_KEGS.mkpath
    FileUtils.ln_s dependency.prefix("0.1"), HOMEBREW_PINNED_KEGS/dep_name

    dependency_keg = Keg.new(dependency.prefix("0.1"))
    dependency_keg.link

    expect(dependency_keg).to be_linked
    expect(dependency).to be_pinned

    fi = described_class.new(dependent)

    expect {
      fi.check_install_sanity
    }.to raise_error(CannotInstallFormulaError)
  end

  specify "install fails with BuildError when a system() call fails" do
    ENV["HOMEBREW_TEST_NO_EXIT_CLEANUP"] = "1"
    ENV["FAILBALL_BUILD_ERROR"] = "1"

    expect {
      temporary_install(Failball.new)
    }.to raise_error(BuildError)
  end

  specify "install fails with a RuntimeError when #install raises" do
    ENV["HOMEBREW_TEST_NO_EXIT_CLEANUP"] = "1"

    expect {
      temporary_install(Failball.new)
    }.to raise_error(RuntimeError)
  end

  describe "#caveats" do
    subject(:formula_installer) { described_class.new(Testball.new) }

    it "shows audit problems if HOMEBREW_DEVELOPER is set" do
      ENV["HOMEBREW_DEVELOPER"] = "1"
      formula_installer.install
      expect(formula_installer).to receive(:audit_installed).and_call_original
      formula_installer.caveats
    end
  end
end
