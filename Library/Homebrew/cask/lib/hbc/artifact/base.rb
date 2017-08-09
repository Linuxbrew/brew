module Hbc
  module Artifact
    class Base
      extend Predicable

      def self.artifact_name
        @artifact_name ||= name.sub(/^.*:/, "").gsub(/(.)([A-Z])/, '\1_\2').downcase
      end

      def self.artifact_english_name
        @artifact_english_name ||= name.sub(/^.*:/, "").gsub(/(.)([A-Z])/, '\1 \2')
      end

      def self.artifact_english_article
        @artifact_english_article ||= (artifact_english_name =~ /^[aeiou]/i) ? "an" : "a"
      end

      def self.artifact_dsl_key
        @artifact_dsl_key ||= artifact_name.to_sym
      end

      def self.artifact_dirmethod
        @artifact_dirmethod ||= "#{artifact_name}dir".to_sym
      end

      def self.me?(cask)
        cask.artifacts[artifact_dsl_key].any?
      end

      attr_reader :force

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
          opoo %Q{Unknown arguments to #{description} -- #{unknown_keys.inspect} (ignored). Running "brew update; brew cleanup; brew cask cleanup" will likely fix it.}
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

      def summary
        {}
      end

      attr_predicate :force?, :verbose?

      def initialize(cask, command: SystemCommand, force: false, verbose: false)
        @cask = cask
        @command = command
        @force = force
        @verbose = verbose
      end
    end
  end
end
