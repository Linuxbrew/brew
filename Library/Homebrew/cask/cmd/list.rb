module Cask
  class Cmd
    class List < AbstractCommand
      option "-1", :one, false
      option "--versions", :versions, false
      option "--full-name", :full_name, false

      option "-l", (lambda do |*|
        one = true # rubocop:disable Lint/UselessAssignment
        opoo "Option -l is obsolete! Implying option -1."
      end)

      def run
        args.any? ? list : list_installed
      end

      def list
        casks.each do |cask|
          raise CaskNotInstalledError, cask unless cask.installed?

          if one?
            puts cask.token
          elsif versions?
            puts self.class.format_versioned(cask)
          else
            cask = CaskLoader.load(cask.installed_caskfile)
            self.class.list_artifacts(cask)
          end
        end
      end

      def self.list_artifacts(cask)
        cask.artifacts.group_by(&:class).each do |klass, artifacts|
          next unless klass.respond_to?(:english_description)

          ohai klass.english_description, artifacts.map(&:summarize_installed)
        end
      end

      def list_installed
        installed_casks = Caskroom.casks

        if one?
          puts installed_casks.map(&:to_s)
        elsif versions?
          puts installed_casks.map(&self.class.method(:format_versioned))
        elsif full_name?
          puts installed_casks.map(&:full_name).sort &tap_and_name_comparison
        elsif !installed_casks.empty?
          puts Formatter.columns(installed_casks.map(&:to_s))
        end
      end

      def self.format_versioned(cask)
        cask.to_s.concat(cask.versions.map(&:to_s).join(" ").prepend(" "))
      end

      def self.help
        "with no args, lists installed Casks; given installed Casks, lists staged files"
      end
    end
  end
end
