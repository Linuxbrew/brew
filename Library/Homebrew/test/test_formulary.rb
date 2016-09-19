require "testing_env"
require "formula"
require "formula_installer"
require "utils/bottles"

class FormularyTest < Homebrew::TestCase
  def test_class_naming
    assert_equal "ShellFm", Formulary.class_s("shell.fm")
    assert_equal "Fooxx", Formulary.class_s("foo++")
    assert_equal "SLang", Formulary.class_s("s-lang")
    assert_equal "PkgConfig", Formulary.class_s("pkg-config")
    assert_equal "FooBar", Formulary.class_s("foo_bar")
    assert_equal "OpensslAT11", Formulary.class_s("openssl@1.1")
  end
end

class FormularyFactoryTest < Homebrew::TestCase
  def setup
    @name = "testball_bottle"
    @path = CoreTap.new.formula_dir/"#{@name}.rb"
    @bottle_dir = Pathname.new("#{File.expand_path("..", __FILE__)}/bottles")
    @bottle = @bottle_dir/"testball_bottle-0.1.#{Utils::Bottles.tag}.bottle.tar.gz"
    @path.write <<-EOS.undent
      class #{Formulary.class_s(@name)} < Formula
        url "file://#{File.expand_path("..", __FILE__)}/tarballs/testball-0.1.tbz"
        sha256 TESTBALL_SHA256

        bottle do
          cellar :any_skip_relocation
          root_url "file://#{@bottle_dir}"
          sha256 "9abc8ce779067e26556002c4ca6b9427b9874d25f0cafa7028e05b5c5c410cb4" => :#{Utils::Bottles.tag}
        end

        def install
          prefix.install "bin"
          prefix.install "libexec"
        end
      end
    EOS
  end

  def teardown
    @path.unlink
  end

  def test_factory
    assert_kind_of Formula, Formulary.factory(@name)
  end

  def test_factory_with_fully_qualified_name
    assert_kind_of Formula, Formulary.factory("homebrew/core/#{@name}")
  end

  def test_formula_unavailable_error
    assert_raises(FormulaUnavailableError) { Formulary.factory("not_existed_formula") }
  end

  def test_formula_class_unavailable_error
    name = "giraffe"
    path = CoreTap.new.formula_dir/"#{name}.rb"
    path.write "class Wrong#{Formulary.class_s(name)} < Formula\nend\n"

    assert_raises(FormulaClassUnavailableError) { Formulary.factory(name) }
  ensure
    path.unlink
  end

  def test_factory_from_path
    assert_kind_of Formula, Formulary.factory(@path)
  end

  def test_factory_from_url
    formula = shutup { Formulary.factory("file://#{@path}") }
    assert_kind_of Formula, formula
  ensure
    formula.path.unlink
  end

  def test_factory_from_bottle
    formula = Formulary.factory(@bottle)
    assert_kind_of Formula, formula
    assert_equal @bottle.realpath, formula.local_bottle_path
  end

  def test_factory_from_alias
    alias_dir = CoreTap.instance.alias_dir
    alias_dir.mkpath
    alias_path = alias_dir/"foo"
    FileUtils.ln_s @path, alias_path
    result = Formulary.factory("foo")
    assert_kind_of Formula, result
    assert_equal alias_path.to_s, result.alias_path
  ensure
    alias_dir.rmtree
  end

  def test_factory_from_rack_and_from_keg
    formula = Formulary.factory(@path)
    installer = FormulaInstaller.new(formula)
    shutup { installer.install }
    keg = Keg.new(formula.prefix)
    f = Formulary.from_rack(formula.rack)
    assert_kind_of Formula, f
    assert_kind_of Tab, f.build
    f = Formulary.from_keg(keg)
    assert_kind_of Formula, f
    assert_kind_of Tab, f.build
  ensure
    keg.unlink
    keg.uninstall
    formula.clear_cache
    formula.bottle.clear_cache
  end

  def test_load_from_contents
    assert_kind_of Formula, Formulary.from_contents(@name, @path, @path.read)
  end

  def test_to_rack
    assert_equal HOMEBREW_CELLAR/@name, Formulary.to_rack(@name)
    (HOMEBREW_CELLAR/@name).mkpath
    assert_equal HOMEBREW_CELLAR/@name, Formulary.to_rack(@name)
    assert_raises(TapFormulaUnavailableError) { Formulary.to_rack("a/b/#{@name}") }
  ensure
    FileUtils.rm_rf HOMEBREW_CELLAR/@name
  end
end

class FormularyTapFactoryTest < Homebrew::TestCase
  def setup
    @name = "foo"
    @tap = Tap.new "homebrew", "foo"
    @path = @tap.path/"#{@name}.rb"
    @code = <<-EOS.undent
      class #{Formulary.class_s(@name)} < Formula
        url "foo-1.0"
      end
    EOS
    @path.write @code
  end

  def teardown
    @tap.path.rmtree
  end

  def test_factory_tap_formula
    assert_kind_of Formula, Formulary.factory(@name)
  end

  def test_factory_tap_alias
    alias_dir = @tap.path/"Aliases"
    alias_dir.mkpath
    FileUtils.ln_s @path, alias_dir/"bar"
    assert_kind_of Formula, Formulary.factory("bar")
  end

  def test_tap_formula_unavailable_error
    assert_raises(TapFormulaUnavailableError) { Formulary.factory("#{@tap}/not_existed_formula") }
  end

  def test_factory_tap_formula_with_fully_qualified_name
    assert_kind_of Formula, Formulary.factory("#{@tap}/#{@name}")
  end

  def test_factory_ambiguity_tap_formulae
    another_tap = Tap.new "homebrew", "bar"
    (another_tap.path/"#{@name}.rb").write @code
    assert_raises(TapFormulaAmbiguityError) { Formulary.factory(@name) }
  ensure
    another_tap.path.rmtree
  end
end

class FormularyTapPriorityTest < Homebrew::TestCase
  def setup
    @name = "foo"
    @core_path = CoreTap.new.formula_dir/"#{@name}.rb"
    @tap = Tap.new "homebrew", "foo"
    @tap_path = @tap.path/"#{@name}.rb"
    code = <<-EOS.undent
      class #{Formulary.class_s(@name)} < Formula
        url "foo-1.0"
      end
    EOS
    @core_path.write code
    @tap_path.write code
  end

  def teardown
    @core_path.unlink
    @tap.path.rmtree
  end

  def test_find_with_priority_core_formula
    formula = Formulary.find_with_priority(@name)
    assert_kind_of Formula, formula
    assert_equal @core_path, formula.path
  end

  def test_find_with_priority_tap_formula
    @tap.pin
    formula = shutup { Formulary.find_with_priority(@name) }
    assert_kind_of Formula, formula
    assert_equal @tap_path.realpath, formula.path
  ensure
    @tap.pinned_symlink_path.parent.parent.rmtree
  end
end
