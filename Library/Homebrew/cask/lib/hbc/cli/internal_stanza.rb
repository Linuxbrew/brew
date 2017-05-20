module Hbc
  class CLI
    class InternalStanza < InternalUseBase
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

      def self.run(*args)
        new(*args).run
      end

      def initialize(*args)
        raise ArgumentError, "No stanza given." if args.empty?

        @table = args.include? "--table"
        @quiet = args.include? "--quiet"
        @format = :to_yaml if args.include? "--yaml"
        @format = :inspect if args.include? "--inspect"
        @cask_tokens = self.class.cask_tokens_from(args)
        @stanza = @cask_tokens.shift.to_sym
        @cask_tokens = Hbc.all_tokens if @cask_tokens.empty?
      end

      def run
        retval = print_stanzas

        # retval is ternary: true/false/nil
        if retval.nil?
          exit 1 if @quiet
          raise CaskError, "nothing to print"
        elsif !retval
          exit 1 if @quiet
          raise CaskError, "print incomplete"
        end
      end

      def print_stanzas
        count = 0
        if ARTIFACTS.include?(@stanza)
          artifact_name = @stanza
          @stanza = :artifacts
        end

        @cask_tokens.each do |cask_token|
          print "#{cask_token}\t" if @table

          begin
            cask = CaskLoader.load(cask_token)
          rescue StandardError
            opoo "Cask '#{cask_token}' was not found" unless @quiet
            puts ""
            next
          end

          unless cask.respond_to?(@stanza)
            opoo "no such stanza '#{@stanza}' on Cask '#{cask_token}'" unless @quiet
            puts ""
            next
          end

          begin
            value = cask.send(@stanza)
          rescue StandardError
            opoo "failure calling '#{@stanza}' on Cask '#{cask_token}'" unless @quiet
            puts ""
            next
          end

          if artifact_name && !value.key?(artifact_name)
            opoo "no such stanza '#{artifact_name}' on Cask '#{cask_token}'" unless @quiet
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

          count += 1
        end
        count.zero? ? nil : count == @cask_tokens.length
      end

      def self.help
        "extract and render a specific stanza for the given Casks"
      end
    end
  end
end
