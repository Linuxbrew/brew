module Superenv
  class << self
    undef bin

    # @private
    def bin
      return unless DevelopmentTools.installed?

      (HOMEBREW_SHIMS_PATH/"mac/super").realpath
    end
  end

  alias x11? x11

  undef homebrew_extra_paths,
        homebrew_extra_pkg_config_paths, homebrew_extra_aclocal_paths,
        homebrew_extra_isystem_paths, homebrew_extra_library_paths,
        homebrew_extra_cmake_include_paths,
        homebrew_extra_cmake_library_paths,
        homebrew_extra_cmake_frameworks_paths,
        determine_cccfg, set_x11_env_if_installed

  def homebrew_extra_paths
    paths = []
    # On 10.9, there are shims for all tools in /usr/bin.
    # On 10.7 and 10.8 we need to add these directories ourselves.
    if MacOS::Xcode.without_clt? && MacOS.version <= "10.8"
      paths << "#{MacOS::Xcode.prefix}/usr/bin"
      paths << "#{MacOS::Xcode.toolchain_path}/usr/bin"
    end

    paths << MacOS::X11.bin.to_s if x11?
    paths
  end

  # @private
  def homebrew_extra_pkg_config_paths
    paths = \
      ["/usr/lib/pkgconfig", "#{HOMEBREW_LIBRARY}/Homebrew/os/mac/pkgconfig/#{MacOS.version}"]
    paths << "#{MacOS::X11.lib}/pkgconfig" << "#{MacOS::X11.share}/pkgconfig" if x11?
    paths
  end

  def homebrew_extra_aclocal_paths
    paths = []
    paths << "#{MacOS::X11.share}/aclocal" if x11?
    paths
  end

  def homebrew_extra_isystem_paths
    paths = []
    paths << "#{effective_sysroot}/usr/include/libxml2" unless deps.any? { |d| d.name == "libxml2" }
    paths << "#{effective_sysroot}/usr/include/apache2" if MacOS::Xcode.without_clt?
    paths << MacOS::X11.include.to_s << "#{MacOS::X11.include}/freetype2" if x11?
    paths << "#{effective_sysroot}/System/Library/Frameworks/OpenGL.framework/Versions/Current/Headers"
    paths
  end

  def homebrew_extra_library_paths
    paths = []
    if compiler == :llvm_clang
      if !MacOS.sdk_path_if_needed
        paths << "/usr/lib"
      else
        paths << "#{MacOS.sdk_path}/usr/lib"
      end
      paths << Formula["llvm"].opt_lib.to_s
    end
    paths << MacOS::X11.lib.to_s if x11?
    paths << "#{effective_sysroot}/System/Library/Frameworks/OpenGL.framework/Versions/Current/Libraries"
    paths
  end

  def homebrew_extra_cmake_include_paths
    paths = []
    paths << "#{effective_sysroot}/usr/include/libxml2" unless deps.any? { |d| d.name == "libxml2" }
    paths << "#{effective_sysroot}/usr/include/apache2" if MacOS::Xcode.without_clt?
    paths << MacOS::X11.include.to_s << "#{MacOS::X11.include}/freetype2" if x11?
    paths << "#{effective_sysroot}/System/Library/Frameworks/OpenGL.framework/Versions/Current/Headers"
    paths
  end

  def homebrew_extra_cmake_library_paths
    paths = []
    paths << MacOS::X11.lib.to_s if x11?
    paths << "#{effective_sysroot}/System/Library/Frameworks/OpenGL.framework/Versions/Current/Libraries"
    paths
  end

  def homebrew_extra_cmake_frameworks_paths
    paths = []
    paths << "#{effective_sysroot}/System/Library/Frameworks" if MacOS::Xcode.without_clt?
    paths
  end

  def determine_cccfg
    s = ""
    # Fix issue with sed barfing on unicode characters on Mountain Lion
    s << "s" if MacOS.version >= :mountain_lion
    # Fix issue with >= 10.8 apr-1-config having broken paths
    s << "a" if MacOS.version >= :mountain_lion
    s
  end

  def effective_sysroot
    MacOS.sdk_path_if_needed&.to_s
  end

  def set_x11_env_if_installed
    ENV.x11 = MacOS::X11.installed?
  end

  # @private
  def setup_build_environment(formula = nil)
    generic_setup_build_environment(formula)
    self["HOMEBREW_SDKROOT"] = effective_sysroot

    # Filter out symbols known not to be defined since GNU Autotools can't
    # reliably figure this out with Xcode 8 and above.
    if MacOS.version == "10.12" && MacOS::Xcode.version >= "9.0"
      %w[fmemopen futimens open_memstream utimensat].each do |s|
        ENV["ac_cv_func_#{s}"] = "no"
      end
    elsif MacOS.version == "10.11" && MacOS::Xcode.version >= "8.0"
      %w[basename_r clock_getres clock_gettime clock_settime dirname_r
         getentropy mkostemp mkostemps timingsafe_bcmp].each do |s|
        ENV["ac_cv_func_#{s}"] = "no"
      end

      ENV["ac_cv_search_clock_gettime"] = "no"

      # works around libev.m4 unsetting ac_cv_func_clock_gettime
      ENV["ac_have_clock_syscall"] = "no"
    end

    # On 10.9, the tools in /usr/bin proxy to the active developer directory.
    # This means we can use them for any combination of CLT and Xcode.
    self["HOMEBREW_PREFER_CLT_PROXIES"] = "1" if MacOS.version >= "10.9"
  end

  def no_weak_imports
    append_to_cccfg "w" if no_weak_imports_support?
  end
end
