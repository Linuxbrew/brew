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

    def check_writable_install_location
      if HOMEBREW_CELLAR.exist? && !HOMEBREW_CELLAR.writable_real?
        raise "Cannot write to #{HOMEBREW_CELLAR}"
      end
      prefix_writable = HOMEBREW_PREFIX.writable_real? || HOMEBREW_PREFIX.to_s == "/usr/local"
      raise "Cannot write to #{HOMEBREW_PREFIX}" unless prefix_writable
    end

    def check_development_tools
      return unless OS.mac?
      checks = Diagnostic::Checks.new
      failed = false
      checks.fatal_development_tools_checks.each do |check|
        out = checks.send(check)
        next if out.nil?
        failed ||= true
        ofail out
      end
      exit 1 if failed
    end

    def check_cellar
      FileUtils.mkdir_p HOMEBREW_CELLAR unless File.exist? HOMEBREW_CELLAR
    rescue
      raise <<~EOS
        Could not create #{HOMEBREW_CELLAR}
        Check you have permission to write to #{HOMEBREW_CELLAR.parent}
      EOS
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

    def perform_preinstall_checks
      check_ppc
      check_writable_install_location
      check_cellar
      return if OS.mac?
      symlink_ld_so
      symlink_host_gcc
    end
  end
end
