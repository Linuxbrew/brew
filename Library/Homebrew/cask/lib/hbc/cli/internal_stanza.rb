module Hbc
  class CLI
    class InternalStanza < AbstractInternalCommand
      # Syntax
      #
      #     brew cask _stanza <stanza_name> [ --table | --yaml | --inspect | --quiet ] [ <cask_token> ... ]
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
      #     brew cask _stanza app       --table alfred google-chrome adium voicemac logisim vagrant
      #     brew cask _stanza url       --table alfred google-chrome adium voicemac logisim vagrant
      #     brew cask _stanza version   --table alfred google-chrome adium voicemac logisim vagrant
      #     brew cask _stanza artifacts --table --inspect alfred google-chrome adium voicemac logisim vagrant
      #     brew cask _stanza artifacts --table --yaml    alfred google-chrome adium voicemac logisim vagrant
      #

      # TODO: this should be retrievable from Hbc::DSL
      ARTIFACTS = Set.new [
        :app,
        :suite,
        :artifact,
        :prefpane,
        :qlplugin,
        :dictionary,
        :font,
        :service,
        :colorpicker,
        :binary,
        :input_method,
        :internet_plugin,
        :audio_unit_plugin,
        :vst_plugin,
        :vst3_plugin,
        :screen_saver,
        :pkg,
        :installer,
        :stage_only,
        :nested_container,
        :uninstall,
        :preflight,
        :postflight,
        :uninstall_preflight,
        :uninstall_postflight,
      ]

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
        @format = :inspect if inspect?
      end

      def run
        return unless print_stanzas == :incomplete
        exit 1 if quiet?
        raise CaskError, "Print incomplete."
      end

      def print_stanzas
        if ARTIFACTS.include?(stanza)
          artifact_name = stanza
          @stanza = :artifacts
        end

        casks(alternative: -> { Hbc.all }).each do |cask|
          print "#{cask}\t" if table?

          unless cask.respond_to?(stanza)
            opoo "no such stanza '#{stanza}' on Cask '#{cask}'" unless quiet?
            puts ""
            next
          end

          begin
            value = cask.send(@stanza)
          rescue StandardError
            opoo "failure calling '#{stanza}' on Cask '#{cask}'" unless quiet?
            puts ""
            next
          end

          if artifact_name && !value.key?(artifact_name)
            opoo "no such stanza '#{artifact_name}' on Cask '#{cask}'" unless quiet?
            puts ""
            next
          end

          value = value.fetch(artifact_name).to_a.flatten if artifact_name

          if @format
            puts value.send(@format)
          elsif artifact_name || value.is_a?(Symbol)
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
