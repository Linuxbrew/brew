module Hbc
  class CLI
    class InternalDump < InternalUseBase
      def self.run(*args)
        new(*args).run
      end

      def initialize(*args)
        @cask_tokens = self.class.cask_tokens_from(args)
        raise CaskUnspecifiedError if @cask_tokens.empty?
      end

      def run
        retval = dump_casks
        # retval is ternary: true/false/nil

        raise CaskError, "nothing to dump" if retval.nil?
        raise CaskError, "dump incomplete" unless retval
      end

      def dump_casks
        count = 0
        @cask_tokens.each do |cask_token|
          begin
            cask = CaskLoader.load(cask_token)
            count += 1
            cask.dumpcask
          rescue StandardError => e
            opoo "#{cask_token} was not found or would not load: #{e}"
          end
        end
        count.zero? ? nil : count == @cask_tokens.length
      end

      def self.help
        "dump the given Cask in YAML format"
      end
    end
  end
end
