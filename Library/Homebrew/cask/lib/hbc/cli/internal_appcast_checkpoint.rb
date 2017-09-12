module Hbc
  class CLI
    class InternalAppcastCheckpoint < AbstractInternalCommand
      option "--calculate", :calculate, false

      def initialize(*)
        super
        raise CaskUnspecifiedError if args.empty?
      end

      def run
        if args.all? { |t| t =~ %r{^https?://} && t !~ /\.rb$/ }
          self.class.appcask_checkpoint_for_url(args)
        else
          self.class.appcask_checkpoint(casks, calculate?)
        end
      end

      def self.appcask_checkpoint_for_url(urls)
        urls.each do |url|
          appcast = DSL::Appcast.new(url)
          puts appcast.calculate_checkpoint[:checkpoint]
        end
      end

      def self.appcask_checkpoint(casks, calculate)
        casks.each do |cask|
          if cask.appcast.nil?
            opoo "Cask '#{cask}' is missing an `appcast` stanza."
          else
            checkpoint = if calculate
              result = cask.appcast.calculate_checkpoint
              result[:checkpoint]
            else
              cask.appcast.checkpoint
            end

            if calculate && checkpoint.nil?
              onoe "Could not retrieve `appcast` checkpoint for cask '#{cask}': #{result[:command_result].stderr}"
            elsif casks.count > 1
              puts "#{checkpoint}  #{cask}"
            else
              puts checkpoint
            end
          end
        end
      end

      def self.help
        "prints or calculates a given Cask's or URL's appcast checkpoint"
      end

      def self.needs_init?
        true
      end
    end
  end
end
