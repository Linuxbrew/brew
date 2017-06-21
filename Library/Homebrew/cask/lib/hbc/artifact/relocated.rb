require "hbc/artifact/base"

require "hbc/utils/hash_validator"

module Hbc
  module Artifact
    class Relocated < Base
      def summary
        {
          english_description: self.class.english_description,
          contents:            @cask.artifacts[self.class.artifact_dsl_key].map(&method(:summarize_artifact)).compact,
        }
      end

      attr_reader :source, :target

      def printable_target
        target.to_s.sub(/^#{ENV['HOME']}(#{File::SEPARATOR}|$)/, "~/")
      end

      ALT_NAME_ATTRIBUTE = "com.apple.metadata:kMDItemAlternateNames".freeze

      # Try to make the asset searchable under the target name.  Spotlight
      # respects this attribute for many filetypes, but ignores it for App
      # bundles. Alfred 2.2 respects it even for App bundles.
      def add_altname_metadata(file, altname)
        return if altname.casecmp(file.basename).zero?
        odebug "Adding #{ALT_NAME_ATTRIBUTE} metadata"
        altnames = @command.run("/usr/bin/xattr",
                                args:         ["-p", ALT_NAME_ATTRIBUTE, file.to_s],
                                print_stderr: false).stdout.sub(/\A\((.*)\)\Z/, '\1')
        odebug "Existing metadata is: '#{altnames}'"
        altnames.concat(", ") unless altnames.empty?
        altnames.concat(%Q("#{altname}"))
        altnames = "(#{altnames})"

        # Some packges are shipped as u=rx (e.g. Bitcoin Core)
        @command.run!("/bin/chmod", args: ["--", "u+rw", file, file.realpath])

        @command.run!("/usr/bin/xattr",
                      args:         ["-w", ALT_NAME_ATTRIBUTE, altnames, file],
                      print_stderr: false)
      end

      def each_artifact
        @cask.artifacts[self.class.artifact_dsl_key].each do |artifact|
          load_specification(artifact)
          yield
        end
      end

      def load_specification(artifact_spec)
        source_string, target_hash = artifact_spec
        raise CaskInvalidError if source_string.nil?
        @source = @cask.staged_path.join(source_string)
        if target_hash
          raise CaskInvalidError unless target_hash.respond_to?(:keys)
          target_hash.extend(HashValidator).assert_valid_keys(:target)
          @target = Hbc.send(self.class.artifact_dirmethod).join(target_hash[:target])
        else
          @target = Hbc.send(self.class.artifact_dirmethod).join(source.basename)
        end
      end
    end
  end
end
