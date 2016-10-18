module FormulaCompat
  def x11_installed?
    odeprecated "Formula#x11_installed?", "MacOS::X11.installed?"
    MacOS::X11.installed?
  end

  def snow_leopard_64?
    odeprecated "Formula#snow_leopard_64?", "MacOS.prefer_64_bit?"
    MacOS.prefer_64_bit?
  end
end

class Formula
  include FormulaCompat
  extend FormulaCompat

  def std_cmake_parameters
    odeprecated "Formula#std_cmake_parameters", "Formula#std_cmake_args"
    "-DCMAKE_INSTALL_PREFIX='#{prefix}' -DCMAKE_BUILD_TYPE=None -DCMAKE_FIND_FRAMEWORK=LAST -Wno-dev"
  end

  def cxxstdlib_check(check_type)
    odeprecated "Formula#cxxstdlib_check in install",
                "Formula.cxxstdlib_check outside install"
    self.class.cxxstdlib_check check_type
  end

  def self.bottle_sha1(*)
    odeprecated "Formula.bottle_sha1"
  end

  def self.all
    odeprecated "Formula.all", "Formula.map"
    map
  end

  def self.canonical_name(name)
    odeprecated "Formula.canonical_name", "Formulary.canonical_name"
    Formulary.canonical_name(name)
  end

  def self.class_s(name)
    odeprecated "Formula.class_s", "Formulary.class_s"
    Formulary.class_s(name)
  end

  def self.factory(name)
    odeprecated "Formula.factory", "Formulary.factory"
    Formulary.factory(name)
  end

  def self.require_universal_deps
    odeprecated "Formula.require_universal_deps"
    define_method(:require_universal_deps?) { true }
  end

  def self.path(name)
    odeprecated "Formula.path", "Formulary.core_path"
    Formulary.core_path(name)
  end

  DATA = :DATA

  def patches
    # Don't print deprecation warning because this method is inherited
    # when used.
    {}
  end

  def python(_options = {}, &_block)
    odeprecated "Formula#python"
    yield if block_given?
    PythonRequirement.new
  end
  alias python2 python
  alias python3 python

  def startup_plist
    odeprecated "Formula#startup_plist", "Formula#plist"
  end
end
