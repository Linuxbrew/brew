module Superenv
  alias x11? x11

  # @private
  def self.bin
    (HOMEBREW_SHIMS_PATH/"linux/super").realpath
  end

  def xorg_recursive_deps
    return [] unless xorg_installed?
    @xorg_deps ||= Formula["linuxbrew/xorg/xorg"].recursive_dependencies.map(&:to_formula)
  rescue FormulaUnavailableError
    []
  end

  def homebrew_extra_paths
    paths = []
    binutils = Formula["binutils"]
    paths << binutils.opt_bin if binutils.installed?
    paths += xorg_recursive_deps.map(&:opt_bin) if x11?
    paths
  rescue FormulaUnavailableError
    # Fix for brew tests, which uses NullLoader.
    []
  end

  def determine_rpath_paths
    paths = ["#{HOMEBREW_PREFIX}/lib"]
    paths += run_time_deps.map { |d| d.opt_lib.to_s }
    paths += homebrew_extra_library_paths
    paths.to_path_s
  end

  def determine_dynamic_linker_path(formula)
    if formula && formula.name == "glibc"
      ""
    else
      "#{HOMEBREW_PREFIX}/lib/ld.so"
    end
  end

  # @private
  def homebrew_extra_pkg_config_paths
    paths = []
    if x11?
      libs = xorg_recursive_deps.map(&:lib)
      shares = xorg_recursive_deps.map(&:share)
      libs.each do |lib|
        paths << lib/"pkgconfig"
      end
      shares.each do |share|
        paths << share/"pkgconfig"
      end
    end
    paths
  end

  def homebrew_extra_aclocal_paths
    paths = []
    if x11?
      shares = xorg_recursive_deps.map(&:share)
      shares.each do |share|
        paths << share/"aclocal"
      end
    end
    paths
  end

  def xorg_include_paths
    xorg_recursive_deps.map(&:include)
  end

  def xorg_lib_paths
    xorg_recursive_deps.map(&:lib)
  end

  def homebrew_extra_isystem_paths
    paths = []
    paths += xorg_include_paths if x11?
    paths
  end

  def homebrew_extra_library_paths
    paths = []
    paths += xorg_lib_paths if x11?
    paths
  end

  def homebrew_extra_cmake_include_paths
    paths = []
    paths += xorg_include_paths if x11?
    paths
  end

  def homebrew_extra_cmake_library_paths
    paths = []
    paths += xorg_lib_paths if x11?
    paths
  end

  def set_x11_env_if_installed
    ENV.x11 = xorg_installed?
  end

  def xorg_installed?
    Formula["linuxbrew/xorg/xorg"].installed?
  rescue FormulaUnavailableError
    false
  end
end
