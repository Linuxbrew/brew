require "hardware"
require "extend/ENV/shared"

# TODO: deprecate compiling related codes after it's only used by brew test.
# @private
module Stdenv
  include SharedEnvExtension

  # @private
  SAFE_CFLAGS_FLAGS = "-w -pipe".freeze
  HOMEBREW_ARCH = (ENV["HOMEBREW_ARCH"] || "native").freeze
  DEFAULT_FLAGS = (OS.mac? ? "-march=core2 -msse4" : "-march=#{HOMEBREW_ARCH}").freeze

  def self.extended(base)
    return if ORIGINAL_PATHS.include? HOMEBREW_PREFIX/"bin"
    base.prepend_path "PATH", "#{HOMEBREW_PREFIX}/bin"
  end

  # @private
  def setup_build_environment(formula = nil)
    super

    # Set the default pkg-config search path, overriding the built-in paths
    # Anything in PKG_CONFIG_PATH is searched before paths in this variable
    self["PKG_CONFIG_LIBDIR"] = determine_pkg_config_libdir

    self["MAKEFLAGS"] = "-j#{make_jobs}"

    unless HOMEBREW_PREFIX.to_s == "/usr/local"
      # /usr/local is already an -isystem and -L directory so we skip it
      self["CPPFLAGS"] = "-isystem#{HOMEBREW_PREFIX}/include"
      self["LDFLAGS"] = "-L#{HOMEBREW_PREFIX}/lib"
      # CMake ignores the variables above
      self["CMAKE_PREFIX_PATH"] = HOMEBREW_PREFIX.to_s
    end

    frameworks = HOMEBREW_PREFIX.join("Frameworks")
    if frameworks.directory?
      append "CPPFLAGS", "-F#{frameworks}"
      append "LDFLAGS", "-F#{frameworks}"
      self["CMAKE_FRAMEWORK_PATH"] = frameworks.to_s
    end

    # Os is the default Apple uses for all its stuff so let's trust them
    define_cflags "-Os #{SAFE_CFLAGS_FLAGS}"

    append "LDFLAGS", "-Wl,-headerpad_max_install_names" if OS.mac?

    if OS.linux? && !["glibc", "glibc25"].include?(formula && formula.name)
      if formula
        # Upgrading a package with a shared library can fail if that
        # library is a dependency of a core package, like curl for
        # example, so we also search for the new library in lib and
        # then the previous version of the library in opt_lib.
        # To work around a bug in glibc 2.19 that is fixed in 2.20
        # add both lib and prefix to LD_LIBRARY_PATH.
        # segfault when LD_LIBRARY_PATH is set to non-existent directory.
        # See https://github.com/Linuxbrew/linuxbrew/issues/841
        prepend_path "LD_LIBRARY_PATH", formula.opt_lib
        prepend_create_path "LD_LIBRARY_PATH", formula.prefix
        prepend "LD_LIBRARY_PATH", formula.lib, File::PATH_SEPARATOR
      end

      # Set the search path for header files.
      prepend_path "CPATH", HOMEBREW_PREFIX/"include"
      # Set the dynamic linker and library search path.
      append "LDFLAGS", "-Wl,--dynamic-linker=#{HOMEBREW_PREFIX}/lib/ld.so -Wl,-rpath,#{HOMEBREW_PREFIX}/lib"
      prepend_path "LIBRARY_PATH", HOMEBREW_PREFIX/"lib"
      prepend_path "LD_RUN_PATH", HOMEBREW_PREFIX/"lib"
    end

    if inherit?
      # Inherit CC, CXX and compiler flags from the parent environment.
    elsif respond_to?(compiler)
      send(compiler)
    else
      self.cc = determine_cc
      self.cxx = determine_cxx
      set_cpu_cflags
    end

    return if inherit?
    return unless cc =~ GNU_GCC_REGEXP
    gcc_formula = gcc_version_formula($&)
    append_path "PATH", gcc_formula.opt_bin.to_s
  end
  alias generic_setup_build_environment setup_build_environment

  def homebrew_extra_pkg_config_paths
    []
  end

  def determine_pkg_config_libdir
    paths = []
    paths << "#{HOMEBREW_PREFIX}/lib/pkgconfig"
    paths << "#{HOMEBREW_PREFIX}/share/pkgconfig"
    paths += homebrew_extra_pkg_config_paths
    paths << "/usr/lib/pkgconfig" if OS.mac?
    paths.select { |d| File.directory? d }.join(File::PATH_SEPARATOR)
  end

  # Removes the MAKEFLAGS environment variable, causing make to use a single job.
  # This is useful for makefiles with race conditions.
  # When passed a block, MAKEFLAGS is removed only for the duration of the block and is restored after its completion.
  def deparallelize
    old = self["MAKEFLAGS"]
    remove "MAKEFLAGS", /-j\d+/
    if block_given?
      begin
        yield
      ensure
        self["MAKEFLAGS"] = old
      end
    end

    old
  end

  %w[O3 O2 O1 O0 Os].each do |opt|
    define_method opt do
      remove_from_cflags(/-O./)
      append_to_cflags "-#{opt}"
    end
  end

  # @private
  def determine_cc
    s = super
    DevelopmentTools.locate(s) || Pathname.new(s)
  end

  # @private
  def determine_cxx
    dir, base = determine_cc.split
    dir / base.to_s.sub("gcc", "g++").sub("clang", "clang++").sub(/^cc$/, "c++")
  end

  def gcc_4_0
    super
    set_cpu_cflags "-march=nocona -mssse3"
  end

  def gcc_4_2
    super
    set_cpu_cflags
  end

  GNU_GCC_VERSIONS.each do |n|
    define_method(:"gcc-#{n}") do
      super()
      set_cpu_cflags
    end
  end

  def clang
    super
    replace_in_cflags(/-Xarch_#{Hardware::CPU.arch_32_bit} (-march=\S*)/, '\1')
    # Clang mistakenly enables AES-NI on plain Nehalem
    map = Hardware::CPU.optimization_flags
    map = map.merge(nehalem: "-march=native -Xclang -target-feature -Xclang -aes")
    set_cpu_cflags "-march=native", map
  end

  def minimal_optimization
    define_cflags "-Os #{SAFE_CFLAGS_FLAGS}"
  end
  alias generic_minimal_optimization minimal_optimization

  def no_optimization
    define_cflags SAFE_CFLAGS_FLAGS
  end
  alias generic_no_optimization no_optimization

  # we've seen some packages fail to build when warnings are disabled!
  def enable_warnings
    remove_from_cflags "-w"
  end

  def m64
    append_to_cflags "-m64"
    append "LDFLAGS", "-arch #{Hardware::CPU.arch_64_bit}" if OS.mac?
  end

  def m32
    append_to_cflags "-m32"
    append "LDFLAGS", "-arch #{Hardware::CPU.arch_32_bit}" if OS.mac?
  end

  def universal_binary
    return unless OS.mac?
    check_for_compiler_universal_support

    append_to_cflags Hardware::CPU.universal_archs.as_arch_flags
    append "LDFLAGS", Hardware::CPU.universal_archs.as_arch_flags

    return if compiler == :clang
    return unless Hardware.is_32_bit?
    # Can't mix "-march" for a 32-bit CPU  with "-arch x86_64"
    replace_in_cflags(/-march=\S*/, "-Xarch_#{Hardware::CPU.arch_32_bit} \\0")
  end

  def cxx11
    if compiler == :clang
      append "CXX", "-std=c++11"
      append "CXX", "-stdlib=libc++" if OS.mac?
    elsif gcc_with_cxx11_support?(compiler)
      append "CXX", "-std=c++11"
    else
      raise "The selected compiler doesn't support C++11: #{compiler}"
    end
  end

  def libcxx
    append "CXX", "-stdlib=libc++" if compiler == :clang
  end

  def libstdcxx
    append "CXX", "-stdlib=libstdc++" if compiler == :clang
  end

  def libxml2(); end

  # @private
  def replace_in_cflags(before, after)
    CC_FLAG_VARS.each do |key|
      self[key] = self[key].sub(before, after) if key?(key)
    end
  end

  # Convenience method to set all C compiler flags in one shot.
  def define_cflags(val)
    CC_FLAG_VARS.each { |key| self[key] = val }
  end

  # Sets architecture-specific flags for every environment variable
  # given in the list `flags`.
  # @private
  def set_cpu_flags(flags, default = DEFAULT_FLAGS, map = Hardware::CPU.optimization_flags)
    cflags =~ /(-Xarch_#{Hardware::CPU.arch_32_bit} )-march=/
    xarch = $1.to_s
    remove flags, /(-Xarch_#{Hardware::CPU.arch_32_bit} )?-march=\S*/
    remove flags, /( -Xclang \S+)+/
    remove flags, /-mssse3/
    remove flags, /-msse4(\.\d)?/
    append flags, xarch unless xarch.empty?
    append flags, map.fetch(effective_arch, default)
  end
  alias generic_set_cpu_flags set_cpu_flags

  # @private
  def effective_arch
    if ARGV.build_bottle?
      ARGV.bottle_arch || Hardware.oldest_cpu
    elsif OS.mac? && Hardware::CPU.intel? && !Hardware::CPU.sse4?
      # If the CPU doesn't support SSE4, we cannot trust -march=native or
      # -march=<cpu family> to do the right thing because we might be running
      # in a VM or on a Hackintosh.
      Hardware.oldest_cpu
    else
      Hardware::CPU.family
    end
  end

  # @private
  def set_cpu_cflags(default = DEFAULT_FLAGS, map = Hardware::CPU.optimization_flags)
    set_cpu_flags CC_FLAG_VARS, default, map
  end

  def make_jobs
    # '-j' requires a positive integral argument
    if self["HOMEBREW_MAKE_JOBS"].to_i > 0
      self["HOMEBREW_MAKE_JOBS"].to_i
    else
      Hardware::CPU.cores
    end
  end

  # This method does nothing in stdenv since there's no arg refurbishment
  # @private
  def refurbish_args; end
end

require "extend/os/extend/ENV/std"
