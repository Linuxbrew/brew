require "hbc/artifact/base"

require "hbc/utils/hash_validator"

require "vendor/plist/plist"

module Hbc
  module Artifact
    class Pkg < Base
      attr_reader :pkg_relative_path

      def self.artifact_dsl_key
        :pkg
      end

      def load_pkg_description(pkg_description)
        @pkg_relative_path = pkg_description.shift
        @pkg_install_opts = pkg_description.shift
        begin
          if @pkg_install_opts.respond_to?(:keys)
            @pkg_install_opts.extend(HashValidator).assert_valid_keys(:allow_untrusted, :choices)
          elsif @pkg_install_opts
            raise
          end
          raise if pkg_description.nil?
        rescue StandardError
          raise CaskInvalidError.new(@cask, "Bad pkg stanza")
        end
      end

      def pkg_install_opts(opt)
        @pkg_install_opts[opt] if @pkg_install_opts.respond_to?(:keys)
      end

      def install_phase
        @cask.artifacts[:pkg].each { |pkg_description| run_installer(pkg_description) }
      end

      def run_installer(pkg_description)
        load_pkg_description pkg_description
        ohai "Running installer for #{@cask}; your password may be necessary."
        ohai "Package installers may write to any location; options such as --appdir are ignored."
        source = @cask.staged_path.join(pkg_relative_path)
        unless source.exist?
          raise CaskError, "pkg source file not found: '#{source}'"
        end
        args = [
          "-pkg",    source,
          "-target", "/"
        ]
        args << "-verboseR" if verbose?
        args << "-allowUntrusted" if pkg_install_opts :allow_untrusted
        with_choices_file do |choices_path|
          args << "-applyChoiceChangesXML" << choices_path if choices_path
          @command.run!("/usr/sbin/installer", sudo: true, args: args, print_stdout: true)
        end
      end

      def with_choices_file
        return yield nil unless pkg_install_opts(:choices)

        Tempfile.open(["choices", ".xml"]) do |file|
          begin
            file.write Plist::Emit.dump(pkg_install_opts(:choices))
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
