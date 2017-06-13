module Hbc
  class CLI
    class List < AbstractCommand
      option "-1", :one, false
      option "--versions", :versions, false

      option "-l", (lambda do |*|
        one = true # rubocop:disable Lint/UselessAssignment
        opoo "Option -l is obsolete! Implying option -1."
      end)

      def run
        retval = args.any? ? list : list_installed
        raise CaskError, "Listing incomplete." if retval == :incomplete
      end

      def list
        casks.each do |cask|
          raise CaskNotInstalledError, cask unless cask.installed?

          if one?
            puts cask.token
          elsif versions?
            puts self.class.format_versioned(cask)
          else
            cask = CaskLoader.load_from_file(cask.installed_caskfile)
            self.class.list_artifacts(cask)
          end
        end
      end

      def self.list_artifacts(cask)
        Artifact.for_cask(cask).each do |artifact|
          summary = artifact.summary
          ohai summary[:english_description], summary[:contents] unless summary.empty?
        end
      end

      def list_installed
        installed_casks = Hbc.installed

        if one?
          puts installed_casks.map(&:to_s)
        elsif versions?
          puts installed_casks.map(&self.class.method(:format_versioned))
        elsif !installed_casks.empty?
          puts Formatter.columns(installed_casks.map(&:to_s))
        end

        installed_casks.empty? ? :empty : :complete
      end

      def self.format_versioned(cask)
        cask.to_s.concat(cask.versions.map(&:to_s).join(" ").prepend(" "))
      end

      def self.help
        "with no args, lists installed Casks; given installed Casks, lists staged files"
      end

      def self.needs_init?
        true
      end
    end
  end
end
