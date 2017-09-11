require "hbc/artifact/abstract_artifact"

require "hbc/utils/hash_validator"

require "vendor/plist/plist"

module Hbc
  module Artifact
    class Pkg < AbstractArtifact
      attr_reader :pkg_relative_path

      def self.from_args(cask, path, **options)
        options.extend(HashValidator).assert_valid_keys(:allow_untrusted, :choices)
        new(cask, path, **options)
      end

      attr_reader :path, :options

      def initialize(cask, path, **options)
        super(cask)
        @path = cask.staged_path.join(path)
        @options = options
      end

      def summarize
        path.relative_path_from(cask.staged_path).to_s
      end

      def install_phase(**options)
        run_installer(**options)
      end

      private

      def run_installer(command: nil, verbose: false, **options)
        ohai "Running installer for #{cask}; your password may be necessary."
        ohai "Package installers may write to any location; options such as --appdir are ignored."
        unless path.exist?
          raise CaskError, "pkg source file not found: '#{path.relative_path_from(cask.staged_path)}'"
        end
        args = [
          "-pkg",    path,
          "-target", "/"
        ]
        args << "-verboseR" if verbose
        args << "-allowUntrusted" if options.fetch(:allow_untrusted, false)
        with_choices_file do |choices_path|
          args << "-applyChoiceChangesXML" << choices_path if choices_path
          command.run!("/usr/sbin/installer", sudo: true, args: args, print_stdout: true)
        end
      end

      def with_choices_file
        choices = options.fetch(:choices, {})
        return yield nil if choices.empty?

        Tempfile.open(["choices", ".xml"]) do |file|
          begin
            file.write Plist::Emit.dump(choices)
            file.close
            yield file.path
          ensure
            file.unlink
          end
        end
      end
    end
  end
end
