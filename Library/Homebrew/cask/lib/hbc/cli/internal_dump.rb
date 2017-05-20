module Hbc
  class CLI
    class InternalDump < AbstractInternalCommand
      def initialize(*)
        super
        raise CaskUnspecifiedError if args.empty?
      end

      def run
        retval = dump_casks
        # retval is ternary: true/false/nil

        raise CaskError, "nothing to dump" if retval.nil?
        raise CaskError, "dump incomplete" unless retval
      end

      def dump_casks
        count = 0
        args.each do |cask_token|
          begin
            cask = CaskLoader.load(cask_token)
            count += 1
            cask.dumpcask
          rescue StandardError => e
            opoo "#{cask_token} was not found or would not load: #{e}"
          end
        end
        count.zero? ? nil : count == args.length
      end

      def self.help
        "dump the given Cask in YAML format"
      end
    end
  end
end
