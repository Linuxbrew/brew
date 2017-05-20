require "English"

module Hbc
  class CLI
    class Style < Base
      def self.help
        "checks Cask style using RuboCop"
      end

      def self.run(*args)
        new(*args).run
      end

      attr_reader :args
      def initialize(*args)
        @cask_tokens = self.class.cask_tokens_from(args)
        @fix = args.any? { |arg| arg =~ /^--(fix|(auto-?)?correct)$/ }
      end

      def fix?
        @fix
      end

      def run
        install_rubocop
        system "rubocop", *rubocop_args, "--", *cask_paths
        raise CaskError, "style check failed" unless $CHILD_STATUS.success?
        true
      end

      def install_rubocop
        capture_stderr do
          begin
            Homebrew.install_gem_setup_path! "rubocop-cask", HOMEBREW_RUBOCOP_CASK_VERSION, "rubocop"
          rescue SystemExit
            raise CaskError, Tty.strip_ansi($stderr.string).chomp.sub(/\AError: /, "")
          end
        end
      end

      def cask_paths
        @cask_paths ||= if @cask_tokens.empty?
          Hbc.all_tapped_cask_dirs
        elsif @cask_tokens.any? { |file| File.exist?(file) }
          @cask_tokens
        else
          @cask_tokens.map { |token| CaskLoader.path(token) }
        end
      end

      def rubocop_args
        fix? ? autocorrect_args : default_args
      end

      def default_args
        [
          "--require", "rubocop-cask",
          "--force-default-config",
          "--force-exclusion",
          "--format", "simple"
        ]
      end

      def autocorrect_args
        default_args + ["--auto-correct"]
      end
    end
  end
end
