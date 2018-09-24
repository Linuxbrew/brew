require "cask/artifact/relocated"

module Cask
  module Artifact
    class Symlinked < Relocated
      def self.link_type_english_name
        "Symlink"
      end

      def self.english_description
        "#{english_name} #{link_type_english_name}s"
      end

      def install_phase(**options)
        link(**options)
      end

      def uninstall_phase(**options)
        unlink(**options)
      end

      def summarize_installed
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

      private

      def link(**options)
        unless source.exist?
          raise CaskError,
            "It seems the #{self.class.link_type_english_name.downcase} " \
            "source '#{source}' is not there."
        end

        if target.exist? && !target.symlink?
          raise CaskError,
            "It seems there is already #{self.class.english_article} " \
            "#{self.class.english_name} at '#{target}'; not linking."
        end

        ohai "Linking #{self.class.english_name} '#{source.basename}' to '#{target}'."
        create_filesystem_link(**options)
      end

      def unlink(**)
        return unless target.symlink?

        ohai "Unlinking #{self.class.english_name} '#{target}'."
        target.delete
      end

      def create_filesystem_link(command: nil, **_)
        target.dirname.mkpath
        command.run!("/bin/ln", args: ["-h", "-f", "-s", "--", source, target])
        add_altname_metadata(source, target.basename, command: command)
      end
    end
  end
end
