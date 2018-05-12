require "tempfile"
require "utils/shell"
require "os/linux/diagnostic"

module Homebrew
  module Diagnostic
    class Checks
      def check_tmpdir_sticky_bit
        message = generic_check_tmpdir_sticky_bit
        return if message.nil?
        message + <<~EOS
          If you don't have administrative privileges on this machine,
          create a directory and set the HOMEBREW_TEMP environment variable,
          for example:
            install -d -m 1755 ~/tmp
            #{Utils::Shell.set_variable_in_profile("HOMEBREW_TEMP", "~/tmp")}
        EOS
      end

      def check_xdg_data_dirs
        return if ENV["XDG_DATA_DIRS"].to_s.empty?
        return if ENV["XDG_DATA_DIRS"].split("/").include?(HOMEBREW_PREFIX/"share")
        <<~EOS
          Homebrew's share was not found in your XDG_DATA_DIRS but you have
          this variable set to include other locations.
          Some programs like `vapigen` may not work correctly.
          Consider adding Homebrew's share directory to XDG_DATA_DIRS like so:
            #{Utils::Shell.prepend_variable_in_profile("XDG_DATA_DIRS", HOMEBREW_PREFIX/"share")}
        EOS
      end
    end
  end
end
