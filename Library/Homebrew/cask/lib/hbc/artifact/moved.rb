require "hbc/artifact/relocated"

module Hbc
  module Artifact
    class Moved < Relocated
      def self.english_description
        "#{english_name}s"
      end

      def install_phase(**options)
        move(**options)
      end

      def uninstall_phase(**options)
        delete(**options)
      end

      def summarize_installed
        if target.exist?
          "#{printable_target} (#{target.abv})"
        else
          Formatter.error(printable_target, label: "Missing #{self.class.english_name}")
        end
      end

      private

      def move(force: false, command: nil, **options)
        if Utils.path_occupied?(target)
          message = "It seems there is already #{self.class.english_article} #{self.class.english_name} at '#{target}'"
          raise CaskError, "#{message}." unless force
          opoo "#{message}; overwriting."
          delete(force: force, command: command, **options)
        end

        unless source.exist?
          raise CaskError, "It seems the #{self.class.english_name} source '#{source}' is not there."
        end

        ohai "Moving #{self.class.english_name} '#{source.basename}' to '#{target}'."
        target.dirname.mkpath

        if target.parent.writable?
          FileUtils.move(source, target)
        else
          command.run("/bin/mv", args: [source, target], sudo: true)
        end

        add_altname_metadata(target, source.basename, command: command)
      end

      def delete(force: false, command: nil, **_)
        ohai "Removing #{self.class.english_name} '#{target}'."
        raise CaskError, "Cannot remove undeletable #{self.class.english_name}." if MacOS.undeletable?(target)

        return unless Utils.path_occupied?(target)

        if target.parent.writable? && !force
          target.rmtree
        else
          Utils.gain_permissions_remove(target, command: command)
        end
      end
    end
  end
end
