require "diagnostic"
require "fileutils"
require "hardware"
require "development_tools"

module Homebrew
  module Install
    module_function

    def check_ppc
      case Hardware::CPU.type
      when :ppc
        abort <<~EOS
          Sorry, Homebrew does not support your computer's CPU architecture.
          For PPC support, see: https://github.com/mistydemeo/tigerbrew
        EOS
      end
    end

    def attempt_directory_creation
      Keg::MUST_EXIST_DIRECTORIES.each do |dir|
        begin
          FileUtils.mkdir_p(dir) unless dir.exist?
        rescue
          nil
        end
      end
    end

    def perform_development_tools_checks
      fatal_checks(:fatal_development_tools_checks)
    end

    def perform_preinstall_checks
      check_ppc
      attempt_directory_creation
      fatal_checks(:fatal_install_checks)
      return if OS.mac?
      symlink_ld_so
      symlink_host_gcc
    end
    alias generic_perform_preinstall_checks perform_preinstall_checks
    module_function :generic_perform_preinstall_checks

    def fatal_checks(type)
      @checks ||= Diagnostic::Checks.new
      failed = false
      @checks.public_send(type).each do |check|
        out = @checks.public_send(check)
        next if out.nil?

        failed ||= true
        ofail out
      end
      exit 1 if failed
    end

    # Symlink the dynamic linker, ld.so
    def symlink_ld_so
      ld_so = HOMEBREW_PREFIX/"lib/ld.so"
      return if ld_so.readable?
      sys_interpreter = [
        "/lib64/ld-linux-x86-64.so.2",
        "/lib/ld-linux.so.3",
        "/lib/ld-linux.so.2",
        "/lib/ld-linux-armhf.so.3",
        "/lib/ld-linux-aarch64.so.1",
        "/system/bin/linker",
      ].find do |s|
        Pathname.new(s).executable?
      end
      raise "Unable to locate the system's ld.so" unless sys_interpreter
      interpreter = begin
        glibc = Formula["glibc"]
        glibc.installed? ? glibc.lib/"ld-linux-x86-64.so.2" : sys_interpreter
      rescue FormulaUnavailableError
        sys_interpreter
      end
      FileUtils.mkdir_p HOMEBREW_PREFIX/"lib"
      FileUtils.ln_sf interpreter, ld_so
    end

    # Symlink the host's compiler
    def symlink_host_gcc
      version = DevelopmentTools.non_apple_gcc_version "/usr/bin/gcc"
      return if version.null?
      suffix = (version < 5) ? version.to_s[/^\d+\.\d+/] : version.to_s[/^\d+/]
      return if File.executable?("/usr/bin/gcc-#{suffix}") || File.executable?(HOMEBREW_PREFIX/"bin/gcc-#{suffix}")
      FileUtils.mkdir_p HOMEBREW_PREFIX/"bin"
      ["gcc", "g++", "gfortran"].each do |tool|
        source = "/usr/bin/#{tool}"
        dest = HOMEBREW_PREFIX/"bin/#{tool}-#{suffix}"
        next if !File.executable?(source) || File.executable?(dest)
        FileUtils.ln_sf source, dest
      end
    end
  end
end

require "extend/os/install"
