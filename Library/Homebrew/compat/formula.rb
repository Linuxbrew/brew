module FormulaCompat
  def x11_installed?
    odisabled "Formula#x11_installed?", "MacOS::X11.installed?"
  end

  def snow_leopard_64?
    odisabled "Formula#snow_leopard_64?", "MacOS.prefer_64_bit?"
  end
end

class Formula
  include FormulaCompat
  extend FormulaCompat

  def std_cmake_parameters
    odisabled "Formula#std_cmake_parameters", "Formula#std_cmake_args"
  end

  def cxxstdlib_check(_)
    odisabled "Formula#cxxstdlib_check in install",
              "Formula.cxxstdlib_check outside install"
  end

  def self.bottle_sha1(*)
    odisabled "Formula.bottle_sha1"
  end

  def self.all
    odisabled "Formula.all", "Formula.map"
  end

  def self.canonical_name(_)
    odisabled "Formula.canonical_name", "Formulary.canonical_name"
  end

  def self.class_s(_)
    odisabled "Formula.class_s", "Formulary.class_s"
  end

  def self.factory(_)
    odisabled "Formula.factory", "Formulary.factory"
  end

  def self.require_universal_deps
    odisabled "Formula.require_universal_deps"
  end

  def self.path(_)
    odisabled "Formula.path", "Formulary.core_path"
  end

  DATA = :DATA

  def patches
    # Don't print deprecation warning because this method is inherited
    # when used.
    {}
  end

  def python(_options = {}, &_)
    odisabled "Formula#python"
  end
  alias python2 python
  alias python3 python

  def startup_plist
    odisabled "Formula#startup_plist", "Formula#plist"
  end

  def rake(*args)
    odeprecated "FileUtils#rake", "system \"rake\""
    system "rake", *args
  end
end
