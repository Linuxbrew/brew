require "hbc/artifact/relocated"

module Hbc
  module Artifact
    class Moved < Relocated
      def self.english_description
        "#{artifact_english_name}s"
      end

      def install_phase
        each_artifact(&method(:move))
      end

      def uninstall_phase
        each_artifact(&method(:delete))
      end

      private

      def move
        if Utils.path_occupied?(target)
          message = "It seems there is already #{self.class.artifact_english_article} #{self.class.artifact_english_name} at '#{target}'"
          raise CaskError, "#{message}." unless force?
          opoo "#{message}; overwriting."
          delete
        end

        unless source.exist?
          raise CaskError, "It seems the #{self.class.artifact_english_name} source '#{source}' is not there."
        end

        ohai "Moving #{self.class.artifact_english_name} '#{source.basename}' to '#{target}'."
        target.dirname.mkpath

        if target.parent.writable?
          FileUtils.move(source, target)
        else
          SystemCommand.run("/bin/mv", args: [source, target], sudo: true)
        end

        add_altname_metadata target, source.basename.to_s
      end

      def delete
        ohai "Removing #{self.class.artifact_english_name} '#{target}'."
        raise CaskError, "Cannot remove undeletable #{self.class.artifact_english_name}." if MacOS.undeletable?(target)

        return unless Utils.path_occupied?(target)

        if target.parent.writable? && !force
          target.rmtree
        else
          Utils.gain_permissions_remove(target, command: @command)
        end
      end

      def summarize_artifact(artifact_spec)
        load_specification artifact_spec

        if target.exist?
          "#{printable_target} (#{target.abv})"
        else
          Formatter.error(printable_target, label: "Missing #{self.class.artifact_english_name}")
        end
      end
    end
  end
end
