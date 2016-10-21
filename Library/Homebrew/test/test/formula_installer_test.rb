require "testing_env"
require "formula"
require "formula_installer"
require "keg"
require "tab"
require "testball"
require "testball_bottle"

class InstallTests < Homebrew::TestCase
  def temporary_install(formula)
    refute_predicate formula, :installed?

    installer = FormulaInstaller.new(formula)

    shutup { installer.install }

    keg = Keg.new(formula.prefix)

    assert_predicate formula, :installed?

    begin
      Tab.clear_cache
      refute_predicate Tab.for_keg(keg), :poured_from_bottle

      yield formula
    ensure
      Tab.clear_cache
      keg.unlink
      keg.uninstall
      formula.clear_cache
      # there will be log files when sandbox is enable.
      formula.logs.rmtree if formula.logs.directory?
    end

    refute_predicate keg, :exist?
    refute_predicate formula, :installed?
  end

  def test_a_basic_install
    ARGV << "--with-invalid_flag" # added to ensure it doesn't fail install
    temporary_install(Testball.new) do |f|
      # Test that things made it into the Keg
      assert_predicate f.prefix+"readme", :exist?

      assert_predicate f.bin, :directory?
      assert_equal 3, f.bin.children.length

      assert_predicate f.libexec, :directory?
      assert_equal 1, f.libexec.children.length

      refute_predicate f.prefix+"main.c", :exist?

      refute_predicate f.prefix+"license", :exist?

      # Test that things make it into the Cellar
      keg = Keg.new f.prefix
      keg.link

      bin = HOMEBREW_PREFIX+"bin"
      assert_predicate bin, :directory?
      assert_equal 3, bin.children.length
      assert_predicate f.prefix/".brew/testball.rb", :readable?
    end
  end

  def test_bottle_unneeded_formula_install
    DevelopmentTools.stubs(:installed?).returns(false)

    formula = Testball.new
    formula.stubs(:bottle_unneeded?).returns(true)
    formula.stubs(:bottle_disabled?).returns(true)

    refute_predicate formula, :bottled?
    assert_predicate formula, :bottle_unneeded?
    assert_predicate formula, :bottle_disabled?

    temporary_install(formula) do |f|
      assert_predicate f, :installed?
    end
  end

  def test_not_poured_from_bottle_when_compiler_specified
    assert_nil ARGV.cc

    cc_arg = "--cc=clang"
    ARGV << cc_arg
    begin
      temporary_install(TestballBottle.new) do |f|
        tab = Tab.for_formula(f)
        assert_equal "clang", tab.compiler
      end
    ensure
      ARGV.delete_if { |x| x == cc_arg }
    end
  end
end

class FormulaInstallerTests < Homebrew::TestCase
  def test_check_install_sanity_pinned_dep
    dep_name = "dependency"
    dep_path = CoreTap.new.formula_dir/"#{dep_name}.rb"
    dep_path.write <<-EOS.undent
      class #{Formulary.class_s(dep_name)} < Formula
        url "foo"
        version "0.2"
      end
    EOS

    Formulary::FORMULAE.delete(dep_path)
    dependency = Formulary.factory(dep_name)

    dependent = formula do
      url "foo"
      version "0.5"
      depends_on dependency.name.to_s
    end

    dependency.prefix("0.1").join("bin/a").mkpath
    HOMEBREW_PINNED_KEGS.mkpath
    FileUtils.ln_s dependency.prefix("0.1"), HOMEBREW_PINNED_KEGS/dep_name

    dependency_keg = Keg.new(dependency.prefix("0.1"))
    dependency_keg.link

    assert_predicate dependency_keg, :linked?
    assert_predicate dependency, :pinned?

    fi = FormulaInstaller.new(dependent)
    assert_raises(CannotInstallFormulaError) { fi.check_install_sanity }
  ensure
    dependency.unpin
    dependency_keg.unlink
    dependency_keg.uninstall
    dependency.clear_cache
    dep_path.unlink
    Formulary::FORMULAE.delete(dep_path)
  end
end
