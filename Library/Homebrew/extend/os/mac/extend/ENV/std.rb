module Stdenv
  # @private
  def setup_build_environment(formula = nil)
    generic_setup_build_environment formula

    if MacOS.version >= :mountain_lion
      # Mountain Lion's sed is stricter, and errors out when
      # it encounters files with mixed character sets
      delete("LC_ALL")
      self["LC_CTYPE"]="C"
    end

    # Add lib and include etc. from the current macosxsdk to compiler flags:
    macosxsdk MacOS.version

    if MacOS::Xcode.without_clt?
      append_path "PATH", "#{MacOS::Xcode.prefix}/usr/bin"
      append_path "PATH", "#{MacOS::Xcode.toolchain_path}/usr/bin"
    end

    # Leopard's ld needs some convincing that it's building 64-bit
    # See: https://github.com/mistydemeo/tigerbrew/issues/59
    return unless MacOS.version == :leopard && MacOS.prefer_64_bit?
    append "LDFLAGS", "-arch #{Hardware::CPU.arch_64_bit}"

    # Many, many builds are broken thanks to Leopard's buggy ld.
    # Our ld64 fixes many of those builds, though of course we can't
    # depend on it already being installed to build itself.
    ld64 if Formula["ld64"].installed?
  end

  def homebrew_extra_pkg_config_paths
    ["#{HOMEBREW_LIBRARY}/Homebrew/os/mac/pkgconfig/#{MacOS.version}"]
  end

  # Sets architecture-specific flags for every environment variable
  # given in the list `flags`.
  # @private
  def set_cpu_flags(flags, default = DEFAULT_FLAGS, map = Hardware::CPU.optimization_flags)
    generic_set_cpu_flags(flags, default, map)

    # Works around a buggy system header on Tiger
    append flags, "-faltivec" if MacOS.version == :tiger
  end

  def minimal_optimization
    generic_minimal_optimization

    macosxsdk unless MacOS::CLT.installed?
  end

  def no_optimization
    generic_no_optimization

    macosxsdk unless MacOS::CLT.installed?
  end

  def remove_macosxsdk(version = MacOS.version)
    # Clear all lib and include dirs from CFLAGS, CPPFLAGS, LDFLAGS that were
    # previously added by macosxsdk
    version = version.to_s
    remove_from_cflags(/ ?-mmacosx-version-min=10\.\d+/)
    delete("MACOSX_DEPLOYMENT_TARGET")
    delete("CPATH")
    remove "LDFLAGS", "-L#{HOMEBREW_PREFIX}/lib"

    return unless (sdk = MacOS.sdk_path(version)) && !MacOS::CLT.installed?
    delete("SDKROOT")
    remove_from_cflags "-isysroot #{sdk}"
    remove "CPPFLAGS", "-isysroot #{sdk}"
    remove "LDFLAGS", "-isysroot #{sdk}"
    if HOMEBREW_PREFIX.to_s == "/usr/local"
      delete("CMAKE_PREFIX_PATH")
    else
      # It was set in setup_build_environment, so we have to restore it here.
      self["CMAKE_PREFIX_PATH"] = HOMEBREW_PREFIX.to_s
    end
    remove "CMAKE_FRAMEWORK_PATH", "#{sdk}/System/Library/Frameworks"
  end

  def macosxsdk(version = MacOS.version)
    # Sets all needed lib and include dirs to CFLAGS, CPPFLAGS, LDFLAGS.
    remove_macosxsdk
    version = version.to_s
    append_to_cflags("-mmacosx-version-min=#{version}")
    self["MACOSX_DEPLOYMENT_TARGET"] = version
    self["CPATH"] = "#{HOMEBREW_PREFIX}/include"
    prepend "LDFLAGS", "-L#{HOMEBREW_PREFIX}/lib"

    return unless (sdk = MacOS.sdk_path(version)) && !MacOS::CLT.installed?
    # Extra setup to support Xcode 4.3+ without CLT.
    self["SDKROOT"] = sdk
    # Tell clang/gcc where system include's are:
    append_path "CPATH", "#{sdk}/usr/include"
    # The -isysroot is needed, too, because of the Frameworks
    append_to_cflags "-isysroot #{sdk}"
    append "CPPFLAGS", "-isysroot #{sdk}"
    # And the linker needs to find sdk/usr/lib
    append "LDFLAGS", "-isysroot #{sdk}"
    # Needed to build cmake itself and perhaps some cmake projects:
    append_path "CMAKE_PREFIX_PATH", "#{sdk}/usr"
    append_path "CMAKE_FRAMEWORK_PATH", "#{sdk}/System/Library/Frameworks"
  end

  # Some configure scripts won't find libxml2 without help
  def libxml2
    if MacOS::CLT.installed?
      append "CPPFLAGS", "-I/usr/include/libxml2"
    else
      # Use the includes form the sdk
      append "CPPFLAGS", "-I#{MacOS.sdk_path}/usr/include/libxml2"
    end
  end

  def x11
    # There are some config scripts here that should go in the PATH
    append_path "PATH", MacOS::X11.bin.to_s

    # Append these to PKG_CONFIG_LIBDIR so they are searched
    # *after* our own pkgconfig directories, as we dupe some of the
    # libs in XQuartz.
    append_path "PKG_CONFIG_LIBDIR", "#{MacOS::X11.lib}/pkgconfig"
    append_path "PKG_CONFIG_LIBDIR", "#{MacOS::X11.share}/pkgconfig"

    append "LDFLAGS", "-L#{MacOS::X11.lib}"
    append_path "CMAKE_PREFIX_PATH", MacOS::X11.prefix.to_s
    append_path "CMAKE_INCLUDE_PATH", MacOS::X11.include.to_s
    append_path "CMAKE_INCLUDE_PATH", "#{MacOS::X11.include}/freetype2"

    append "CPPFLAGS", "-I#{MacOS::X11.include}"
    append "CPPFLAGS", "-I#{MacOS::X11.include}/freetype2"

    append_path "ACLOCAL_PATH", "#{MacOS::X11.share}/aclocal"

    if MacOS::XQuartz.provided_by_apple? && !MacOS::CLT.installed?
      append_path "CMAKE_PREFIX_PATH", "#{MacOS.sdk_path}/usr/X11"
    end

    append "CFLAGS", "-I#{MacOS::X11.include}" unless MacOS::CLT.installed?
  end

  def no_weak_imports
    append "LDFLAGS", "-Wl,-no_weak_imports" if no_weak_imports_support?
  end
end
