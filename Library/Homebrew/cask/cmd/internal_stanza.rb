module Cask
  class Cmd
    class InternalStanza < AbstractInternalCommand
      # Syntax
      #
      #     brew cask _stanza <stanza_name> [ --quiet ] [ --table | --yaml ] [ <cask_token> ... ]
      #
      # If no tokens are given, then data for all Casks is returned.
      #
      # The pseudo-stanza "artifacts" is available.
      #
      # On failure, a blank line is returned on the standard output.
      #
      # Examples
      #
      #     brew cask _stanza appcast   --table
      #     brew cask _stanza app       --table           alfred google-chrome adium vagrant
      #     brew cask _stanza url       --table           alfred google-chrome adium vagrant
      #     brew cask _stanza version   --table           alfred google-chrome adium vagrant
      #     brew cask _stanza artifacts --table           alfred google-chrome adium vagrant
      #     brew cask _stanza artifacts --table --yaml    alfred google-chrome adium vagrant
      #

      ARTIFACTS =
        DSL::ORDINARY_ARTIFACT_CLASSES.map(&:dsl_key) +
        DSL::ARTIFACT_BLOCK_CLASSES.map(&:dsl_key)

      option "--table",   :table,   false
      option "--quiet",   :quiet,   false
      option "--yaml",    :yaml,    false
      option "--inspect", :inspect, false

      attr_accessor :format
      private :format, :format=

      attr_accessor :stanza
      private :stanza, :stanza=

      def initialize(*)
        super
        raise ArgumentError, "No stanza given." if args.empty?

        @stanza = args.shift.to_sym

        @format = :to_yaml if yaml?

        return if DSL::DSL_METHODS.include?(stanza)

        raise ArgumentError,
          <<~EOS
            Unknown/unsupported stanza: '#{stanza}'
            Check Cask reference for supported stanzas.
          EOS
      end

      def run
        if ARTIFACTS.include?(stanza)
          artifact_name = stanza
          @stanza = :artifacts
        end

        casks(alternative: -> { Cask.to_a }).each do |cask|
          print "#{cask}\t" if table?

          begin
            value = cask.send(stanza)
          rescue
            opoo "failure calling '#{stanza}' on Cask '#{cask}'" unless quiet?
            puts ""
            next
          end

          if stanza == :artifacts
            value = Hash[value.map { |v| [v.class.dsl_key, v.to_s] }]
            value = value[artifact_name] if artifact_name
          end

          if value.nil? || (value.respond_to?(:empty?) && value.empty?)
            stanza_name = artifact_name || stanza
            raise CaskError, "no such stanza '#{stanza_name}' on Cask '#{cask}'"
          end

          if format
            puts value.send(format)
          elsif value.is_a?(Symbol)
            puts value.inspect
          else
            puts value.to_s
          end
        end
      end

      def self.help
        "extract and render a specific stanza for the given Casks"
      end
    end
  end
end
