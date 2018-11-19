module Cask
  class Cmd
    class Style < AbstractCommand
      def self.help
        "checks Cask style using RuboCop"
      end

      option "--fix", :fix, false

      def run
        install_rubocop
        cache_env = { "XDG_CACHE_HOME" => "#{HOMEBREW_CACHE}/style" }
        hide_warnings = debug? ? [] : [ENV["HOMEBREW_RUBY_PATH"], "-W0", "-S"]
        Dir.mktmpdir do |tmpdir|
          system(cache_env, *hide_warnings, "rubocop", *rubocop_args, "--", *cask_paths, chdir: tmpdir)
        end
        raise CaskError, "style check failed" unless $CHILD_STATUS.success?
      end

      def install_rubocop
        capture_stderr do
          begin
            Homebrew.install_gem_setup_path! "rubocop"
          rescue SystemExit
            raise CaskError, Tty.strip_ansi($stderr.string).chomp.sub(/\AError: /, "")
          end
        end
      end

      def cask_paths
        @cask_paths ||= if args.empty?
          Tap.map(&:cask_dir).select(&:directory?)
        elsif args.any? { |file| File.exist?(file) }
          args.map { |path| Pathname(path).expand_path }
        else
          casks.map(&:sourcefile_path)
        end
      end

      def rubocop_args
        fix? ? autocorrect_args : normal_args
      end

      def default_args
        [
          "--force-exclusion",
          "--config", "#{HOMEBREW_LIBRARY}/.rubocop_cask.yml",
          "--format", "simple"
        ]
      end

      def normal_args
        default_args + ["--parallel"]
      end

      def autocorrect_args
        default_args + ["--auto-correct"]
      end
    end
  end
end
