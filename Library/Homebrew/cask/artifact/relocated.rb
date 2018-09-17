require "cask/artifact/abstract_artifact"

require "extend/hash_validator"
using HashValidator

module Cask
  module Artifact
    class Relocated < AbstractArtifact
      def self.from_args(cask, *args)
        source_string, target_hash = args

        if target_hash
          raise CaskInvalidError unless target_hash.respond_to?(:keys)

          target_hash.assert_valid_keys!(:target)
        end

        target_hash ||= {}

        new(cask, source_string, **target_hash)
      end

      def resolve_target(target)
        config.public_send(self.class.dirmethod).join(target)
      end

      attr_reader :source, :target

      def initialize(cask, source, target: nil)
        super(cask)

        @source_string = source.to_s
        @target_string = target.to_s
        source = cask.staged_path.join(source)
        @source = source
        target ||= source.basename
        @target = resolve_target(target)
      end

      def to_a
        [@source_string].tap do |ary|
          ary << { target: @target_string } unless @target_string.empty?
        end
      end

      def summarize
        target_string = @target_string.empty? ? "" : " -> #{@target_string}"
        "#{@source_string}#{target_string}"
      end

      private

      ALT_NAME_ATTRIBUTE = "com.apple.metadata:kMDItemAlternateNames".freeze

      # Try to make the asset searchable under the target name.  Spotlight
      # respects this attribute for many filetypes, but ignores it for App
      # bundles. Alfred 2.2 respects it even for App bundles.
      def add_altname_metadata(file, altname, command: nil)
        return if altname.to_s.casecmp(file.basename.to_s).zero?

        odebug "Adding #{ALT_NAME_ATTRIBUTE} metadata"
        altnames = command.run("/usr/bin/xattr",
                                args:         ["-p", ALT_NAME_ATTRIBUTE, file],
                                print_stderr: false).stdout.sub(/\A\((.*)\)\Z/, '\1')
        odebug "Existing metadata is: '#{altnames}'"
        altnames.concat(", ") unless altnames.empty?
        altnames.concat(%Q("#{altname}"))
        altnames = "(#{altnames})"

        # Some packages are shipped as u=rx (e.g. Bitcoin Core)
        command.run!("/bin/chmod", args: ["--", "u+rw", file, file.realpath])

        command.run!("/usr/bin/xattr",
                      args:         ["-w", ALT_NAME_ATTRIBUTE, altnames, file],
                      print_stderr: false)
      end

      def printable_target
        target.to_s.sub(/^#{ENV['HOME']}(#{File::SEPARATOR}|$)/, "~/")
      end
    end
  end
end
