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
      checks = Diagnostic::Checks.new
      checks.fatal_development_tools_checks.each do |check|
        out = checks.send(check)
        next if out.nil?
        ofail out
      end
      exit 1 if Homebrew.failed?
    end

    def check_cellar
      FileUtils.mkdir_p HOMEBREW_CELLAR unless File.exist? HOMEBREW_CELLAR
    rescue
      raise <<~EOS
        Could not create #{HOMEBREW_CELLAR}
        Check you have permission to write to #{HOMEBREW_CELLAR.parent}
      EOS
    end

    def perform_preinstall_checks
      check_ppc
      check_writable_install_location
      check_development_tools if DevelopmentTools.installed?
      check_cellar
    end
  end
end
