module Hbc
  class CLI
    class InternalAppcastCheckpoint < InternalUseBase
      def self.run(*args)
        calculate = args.include? "--calculate"
        cask_tokens = cask_tokens_from(args)
        raise CaskUnspecifiedError if cask_tokens.empty?

        appcask_checkpoint(cask_tokens, calculate)
      end

      def self.appcask_checkpoint(cask_tokens, calculate)
        count = 0

        cask_tokens.each do |cask_token|
          cask = Hbc.load(cask_token)

          if cask.appcast.nil?
            opoo "Cask '#{cask}' is missing an `appcast` stanza."
          else
            if calculate
              result = cask.appcast.calculate_checkpoint

              checkpoint = result[:checkpoint]
            else
              checkpoint = cask.appcast.checkpoint
            end

            if checkpoint.nil?
              onoe "Could not retrieve `appcast` checkpoint for cask '#{cask}': #{result[:command_result].stderr}"
            else
              puts cask_tokens.count > 1 ? "#{checkpoint}  #{cask}": checkpoint
              count += 1
            end
          end
        end

        count == cask_tokens.count
      end

      def self.help
        "prints (no flag) or calculates ('--calculate') a given Cask's appcast checkpoint"
      end

      def self.needs_init?
        true
      end
    end
  end
end
