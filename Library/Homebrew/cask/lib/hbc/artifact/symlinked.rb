require "hbc/artifact/relocated"

module Hbc
  module Artifact
    class Symlinked < Relocated
      def self.link_type_english_name
        "Symlink"
      end

      def self.english_description
        "#{artifact_english_name} #{link_type_english_name}s"
      end

      def install_phase
        each_artifact(&method(:link))
      end

      def uninstall_phase
        each_artifact(&method(:unlink))
      end

      private

      def link
        unless source.exist?
          raise CaskError, "It seems the #{self.class.link_type_english_name.downcase} source '#{source}' is not there."
        end

        if target.exist? && !target.symlink?
          raise CaskError, "It seems there is already #{self.class.artifact_english_article} #{self.class.artifact_english_name} at '#{target}'; not linking."
        end

        ohai "Linking #{self.class.artifact_english_name} '#{source.basename}' to '#{target}'."
        create_filesystem_link(source, target)
      end

      def unlink
        return unless target.symlink?
        ohai "Unlinking #{self.class.artifact_english_name} '#{target}'."
        target.delete
      end

      def create_filesystem_link(source, target)
        target.dirname.mkpath
        @command.run!("/bin/ln", args: ["-h", "-f", "-s", "--", source, target])
        add_altname_metadata source, target.basename.to_s
      end

      def summarize_artifact(artifact_spec)
        load_specification artifact_spec

        if target.symlink? && target.exist? && target.readlink.exist?
          "#{printable_target} -> #{target.readlink} (#{target.readlink.abv})"
        else
          string = if target.symlink?
            "#{printable_target} -> #{target.readlink}"
          else
            printable_target
          end

          Formatter.error(string, label: "Broken Link")
        end
      end
    end
  end
end
