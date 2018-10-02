require "hardware"
require "extend/ENV/shared"

# @private
module Stdenv
  include SharedEnvExtension

  # @private
  SAFE_CFLAGS_FLAGS = "-w -pipe".freeze
  DEFAULT_FLAGS = "-march=native".freeze

  # @private
  def setup_build_environment(formula = nil)
    super

    self["HOMEBREW_ENV"] = "std"

    PATH.new(ENV["HOMEBREW_PATH"]).each { |p| prepend_path "PATH", p }

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

    append "LDFLAGS", "-Wl,-headerpad_max_install_names"

    send(compiler)

    return unless cc =~ GNU_GCC_REGEXP

    gcc_formula = gcc_version_formula($&)
    append_path "PATH", gcc_formula.opt_bin.to_s
  end
  alias generic_setup_build_environment setup_build_environment

  def homebrew_extra_pkg_config_paths
    []
  end

  def determine_pkg_config_libdir
    PATH.new(
      HOMEBREW_PREFIX/"lib/pkgconfig",
      HOMEBREW_PREFIX/"share/pkgconfig",
      homebrew_extra_pkg_config_paths,
      "/usr/lib/pkgconfig",
    ).existing
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
    dir/base.to_s.sub("gcc", "g++").sub("clang", "clang++")
  end

  def gcc_4_0
    super
    set_cpu_cflags "-march=nocona -mssse3"
  end

  def gcc_4_2
    super
    set_cpu_cflags "-march=core2 -msse4"
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
    set_cpu_cflags DEFAULT_FLAGS, map
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
    append "LDFLAGS", "-arch #{Hardware::CPU.arch_64_bit}"
  end

  def m32
    append_to_cflags "-m32"
    append "LDFLAGS", "-arch #{Hardware::CPU.arch_32_bit}"
  end

  def universal_binary
    check_for_compiler_universal_support

    append_to_cflags Hardware::CPU.universal_archs.as_arch_flags
    append "LDFLAGS", Hardware::CPU.universal_archs.as_arch_flags

    return if compiler_any_clang?
    return unless Hardware.is_32_bit?

    # Can't mix "-march" for a 32-bit CPU  with "-arch x86_64"
    replace_in_cflags(/-march=\S*/, "-Xarch_#{Hardware::CPU.arch_32_bit} \\0")
  end

  def cxx11
    if compiler == :clang
      append "CXX", "-std=c++11"
      append "CXX", "-stdlib=libc++"
    elsif compiler_with_cxx11_support?(compiler)
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
    xarch = Regexp.last_match(1).to_s
    remove flags, /(-Xarch_#{Hardware::CPU.arch_32_bit} )?-march=\S*/
    remove flags, /( -Xclang \S+)+/
    remove flags, /-mssse3/
    remove flags, /-msse4(\.\d)?/
    append flags, xarch unless xarch.empty?
    append flags, map.fetch(effective_arch, default)
  end
  alias generic_set_cpu_flags set_cpu_flags

  def x11; end

  # @private
  def effective_arch
    if ARGV.build_bottle?
      ARGV.bottle_arch || Hardware.oldest_cpu
    elsif Hardware::CPU.intel? && !Hardware::CPU.sse4?
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
    if (jobs = self["HOMEBREW_MAKE_JOBS"].to_i).positive?
      jobs
    else
      Hardware::CPU.cores
    end
  end

  # This method does nothing in stdenv since there's no arg refurbishment
  # @private
  def refurbish_args; end
end

require "extend/os/extend/ENV/std"
