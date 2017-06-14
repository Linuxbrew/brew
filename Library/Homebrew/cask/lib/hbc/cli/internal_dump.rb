module Hbc
  class CLI
    class InternalDump < AbstractInternalCommand
      def initialize(*)
        super
        raise CaskUnspecifiedError if args.empty?
      end

      def run
        raise CaskError, "Dump incomplete." if dump_casks == :incomplet
      end

      def dump_casks
        casks.each(&:dumpcask)
      end

      def self.help
        "dump the given Cask in YAML format"
      end
    end
  end
end
