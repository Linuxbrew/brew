module Cask
  module Artifact
    class AbstractArtifact
      include Comparable
      extend Predicable

      def self.english_name
        @english_name ||= name.sub(/^.*:/, "").gsub(/(.)([A-Z])/, '\1 \2')
      end

      def self.english_article
        @english_article ||= (english_name =~ /^[aeiou]/i) ? "an" : "a"
      end

      def self.dsl_key
        @dsl_key ||= name.sub(/^.*:/, "").gsub(/(.)([A-Z])/, '\1_\2').downcase.to_sym
      end

      def self.dirmethod
        @dirmethod ||= "#{dsl_key}dir".to_sym
      end

      def <=>(other)
        return unless other.class < AbstractArtifact
        return 0 if self.class == other.class

        @@sort_order ||= [ # rubocop:disable Style/ClassVars
          PreflightBlock,
          # The `uninstall` stanza should be run first, as it may
          # depend on other artifacts still being installed.
          Uninstall,
          Installer,
          [
            App,
            Suite,
            Artifact,
            Colorpicker,
            Prefpane,
            Qlplugin,
            Dictionary,
            Font,
            Service,
            InputMethod,
            InternetPlugin,
            AudioUnitPlugin,
            VstPlugin,
            Vst3Plugin,
            ScreenSaver,
          ],
          # `pkg` should be run before `binary`, so
          # targets are created prior to linking.
          Pkg,
          Binary,
          PostflightBlock,
          Zap,
        ].each_with_index.flat_map { |classes, i| [*classes].map { |c| [c, i] } }.to_h

        (@@sort_order[self.class] <=> @@sort_order[other.class]).to_i
      end

      # TODO: this sort of logic would make more sense in dsl.rb, or a
      #       constructor called from dsl.rb, so long as that isn't slow.
      def self.read_script_arguments(arguments, stanza, default_arguments = {}, override_arguments = {}, key = nil)
        # TODO: when stanza names are harmonized with class names,
        #       stanza may not be needed as an explicit argument
        description = key ? "#{stanza} #{key.inspect}" : stanza.to_s

        # backward-compatible string value
        arguments = { executable: arguments } if arguments.is_a?(String)

        # key sanity
        permitted_keys = [:args, :input, :executable, :must_succeed, :sudo, :print_stdout, :print_stderr]
        unknown_keys = arguments.keys - permitted_keys
        unless unknown_keys.empty?
          opoo "Unknown arguments to #{description} -- " \
               "#{unknown_keys.inspect} (ignored). Running " \
               "\"brew update; brew cleanup\" will likely fix it."
        end
        arguments.select! { |k| permitted_keys.include?(k) }

        # key warnings
        override_keys = override_arguments.keys
        ignored_keys = arguments.keys & override_keys
        unless ignored_keys.empty?
          onoe "Some arguments to #{description} will be ignored -- :#{unknown_keys.inspect} (overridden)."
        end

        # extract executable
        executable = arguments.key?(:executable) ? arguments.delete(:executable) : nil

        arguments = default_arguments.merge arguments
        arguments.merge! override_arguments

        [executable, arguments]
      end

      attr_reader :cask, :config

      def initialize(cask)
        @cask = cask
        @config = cask.config
      end

      def to_s
        "#{summarize} (#{self.class.english_name})"
      end
    end
  end
end
