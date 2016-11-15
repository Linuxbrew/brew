require "English"

module Hbc
  class CLI
    class Style < Base
      def self.help
        "checks Cask style using RuboCop"
      end

      def self.run(*args)
        retval = new(args).run
        raise CaskError, "style check failed" unless retval
      end

      attr_reader :args
      def initialize(args)
        @args = args
      end

      def run
        install_rubocop
        system "rubocop", *rubocop_args, "--", *cask_paths
        $CHILD_STATUS.success?
      end

      RUBOCOP_CASK_VERSION = "~> 0.10.6".freeze

      def install_rubocop
        Utils.capture_stderr do
          begin
            Homebrew.install_gem_setup_path! "rubocop-cask", RUBOCOP_CASK_VERSION, "rubocop"
          rescue SystemExit
            raise CaskError, Tty.strip_ansi($stderr.string).chomp.sub(/\AError: /, "")
          end
        end
      end

      def cask_paths
        @cask_paths ||= if cask_tokens.empty?
          Hbc.all_tapped_cask_dirs
        elsif cask_tokens.any? { |file| File.exist?(file) }
          cask_tokens
        else
          cask_tokens.map { |token| Hbc.path(token) }
        end
      end

      def cask_tokens
        @cask_tokens ||= self.class.cask_tokens_from(args)
      end

      def rubocop_args
        fix? ? autocorrect_args : default_args
      end

      def default_args
        [
          "--require", "rubocop-cask",
          "--config", "/dev/null", # always use `rubocop-cask` default config
          "--format", "simple",
          "--force-exclusion"
        ]
      end

      def autocorrect_args
        default_args + ["--auto-correct"]
      end

      def fix?
        args.any? { |arg| arg =~ /--(fix|(auto-?)?correct)/ }
      end
    end
  end
end
