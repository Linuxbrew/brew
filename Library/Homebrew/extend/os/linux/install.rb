module Homebrew
  module Install
    module_function

    DYNAMIC_LINKERS = [
      "/lib64/ld-linux-x86-64.so.2",
      "/lib/ld-linux.so.3",
      "/lib/ld-linux.so.2",
      "/lib/ld-linux-aarch64.so.1",
      "/lib/ld-linux-armhf.so.3",
      "/system/bin/linker64",
      "/system/bin/linker",
    ].freeze

    def symlink_ld_so
      brew_ld_so = HOMEBREW_PREFIX/"lib/ld.so"
      return if brew_ld_so.readable?

      ld_so = HOMEBREW_PREFIX/"opt/glibc/lib/ld-linux-x86-64.so.2"
      unless ld_so.readable?
        ld_so = DYNAMIC_LINKERS.find { |s| File.executable? s }
        raise "Unable to locate the system's dynamic linker" unless ld_so
      end

      FileUtils.mkdir_p HOMEBREW_PREFIX/"lib"
      FileUtils.ln_sf ld_so, brew_ld_so
    end

    def perform_preinstall_checks
      generic_perform_preinstall_checks
      symlink_ld_so
    end
  end
end
