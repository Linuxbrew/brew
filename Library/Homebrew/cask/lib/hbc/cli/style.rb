module Hbc
  class CLI
    class Style < AbstractCommand
      def self.help
        "checks Cask style using RuboCop"
      end

      option "--fix", :fix, false

      def run
        install_rubocop
        cache_env = { "XDG_CACHE_HOME" => "#{HOMEBREW_CACHE}/style" }
        system(cache_env, "rubocop", *rubocop_args, "--", *cask_paths)
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
        @cask_paths ||= if args.empty?
          Hbc.all_tapped_cask_dirs
        elsif args.any? { |file| File.exist?(file) }
          args
        else
          casks.map(&:sourcefile_path)
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
