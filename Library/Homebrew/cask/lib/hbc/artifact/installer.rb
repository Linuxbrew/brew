require "hbc/artifact/abstract_artifact"

module Hbc
  module Artifact
    class Installer < AbstractArtifact
      VALID_KEYS = Set.new [
        :manual,
        :script,
      ]

      module ManualInstaller
        def install_phase(**)
          puts <<-EOS.undent
            To complete the installation of Cask #{cask}, you must also
            run the installer at

              '#{path}'
          EOS
        end
      end

      module ScriptInstaller
        def install_phase(command: nil, **_)
          ohai "Running #{self.class.dsl_key} script '#{path.relative_path_from(cask.staged_path)}'"
          FileUtils.chmod "+x", path unless path.executable?
          command.run(path, **args)
        end
      end

      def self.from_args(cask, **args)
        raise CaskInvalidError.new(cask, "'installer' stanza requires an argument.") if args.empty?

        if args.key?(:script) && !args[:script].respond_to?(:key?)
          if args.key?(:executable)
            raise CaskInvalidError.new(cask, "'installer' stanza gave arguments for both :script and :executable.")
          end

          args[:executable] = args[:script]
          args.delete(:script)
          args = { script: args }
        end

        unless args.keys.count == 1
          raise CaskInvalidError.new(cask, "invalid 'installer' stanza: Only one of #{VALID_KEYS.inspect} is permitted.")
        end

        args.extend(HashValidator).assert_valid_keys(*VALID_KEYS)
        new(cask, **args)
      end

      attr_reader :path, :args

      def initialize(cask, **args)
        super(cask)

        if args.key?(:manual)
          @path = cask.staged_path.join(args[:manual])
          @args = []
          extend(ManualInstaller)
          return
        end

        path, @args = self.class.read_script_arguments(
          args[:script], self.class.dsl_key.to_s, { must_succeed: true, sudo: false }, print_stdout: true
        )
        raise CaskInvalidError.new(cask, "#{self.class.dsl_key} missing executable") if path.nil?

        path = Pathname(path)
        @path = path.absolute? ? path : cask.staged_path.join(path)
        extend(ScriptInstaller)
      end

      def summarize
        path.relative_path_from(cask.staged_path).to_s
      end

      def to_h
        { path: path.relative_path_from(cask.staged_path).to_s }.tap do |h|
          h[:args] = args unless is_a?(ManualInstaller)
        end
      end
    end
  end
end
