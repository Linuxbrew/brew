module Hbc
  module Scopes
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def all
        @all_casks ||= {}
        all_tokens.map { |t| @all_casks[t] ||= load(t) }
      end

      def all_tapped_cask_dirs
        Tap.map(&:cask_dir).compact
      end

      def all_tokens
        Tap.map do |t|
          t.cask_files.map do |p|
            "#{t.name}/#{File.basename(p, ".rb")}"
          end
        end.flatten
      end

      def installed
        # Hbc.load has some DWIM which is slow.  Optimize here
        # by spoon-feeding Hbc.load fully-qualified paths.
        # TODO: speed up Hbc::Source::Tapped (main perf drag is calling Hbc.all_tokens repeatedly)
        # TODO: ability to specify expected source when calling Hbc.load (minor perf benefit)
        Pathname.glob(caskroom.join("*"))
                .map do |caskroom_path|
                  token = caskroom_path.basename.to_s

                  path_to_cask = all_tapped_cask_dirs.find do |tap_dir|
                    tap_dir.join("#{token}.rb").exist?
                  end

                  if path_to_cask
                    Hbc.load(path_to_cask.join("#{token}.rb"))
                  else
                    Hbc.load(token)
                  end
                end
      end
    end
  end
end
