require "diagnostic"
require "fileutils"
require "hardware"
require "development_tools"

module Homebrew
  module Install
    module_function

    def check_cpu
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

    def check_cc_argv
      return unless ARGV.cc

      @checks ||= Diagnostic::Checks.new
      opoo <<~EOS
        You passed `--cc=#{ARGV.cc}`.
        #{@checks.please_create_pull_requests}
      EOS
    end

    def perform_preinstall_checks(all_fatal: false)
      check_cpu
      attempt_directory_creation
      check_cc_argv
      diagnostic_checks(:supported_configuration_checks, fatal: all_fatal)
      diagnostic_checks(:fatal_preinstall_checks)
    end
    alias generic_perform_preinstall_checks perform_preinstall_checks
    module_function :generic_perform_preinstall_checks

    def perform_build_from_source_checks(all_fatal: false)
      diagnostic_checks(:fatal_build_from_source_checks)
      diagnostic_checks(:build_from_source_checks, fatal: all_fatal)
    end

    def diagnostic_checks(type, fatal: true)
      @checks ||= Diagnostic::Checks.new
      failed = false
      @checks.public_send(type).each do |check|
        out = @checks.public_send(check)
        next if out.nil?

        if fatal
          failed ||= true
          ofail out
        else
          opoo out
        end
      end
      exit 1 if failed && fatal
    end
  end
end

require "extend/os/install"
