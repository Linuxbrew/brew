require "set"
require "locale"

require "hbc/dsl/appcast"
require "hbc/dsl/base"
require "hbc/dsl/caveats"
require "hbc/dsl/conflicts_with"
require "hbc/dsl/container"
require "hbc/dsl/depends_on"
require "hbc/dsl/gpg"
require "hbc/dsl/installer"
require "hbc/dsl/postflight"
require "hbc/dsl/preflight"
require "hbc/dsl/stanza_proxy"
require "hbc/dsl/uninstall_postflight"
require "hbc/dsl/uninstall_preflight"
require "hbc/dsl/version"

module Hbc
  class DSL
    ORDINARY_ARTIFACT_TYPES = [
      :app,
      :artifact,
      :audio_unit_plugin,
      :binary,
      :colorpicker,
      :dictionary,
      :font,
      :input_method,
      :internet_plugin,
      :pkg,
      :prefpane,
      :qlplugin,
      :screen_saver,
      :service,
      :stage_only,
      :suite,
      :vst_plugin,
      :vst3_plugin,
    ].freeze

    ACTIVATABLE_ARTIFACT_TYPES = ([:installer, *ORDINARY_ARTIFACT_TYPES] - [:stage_only]).freeze

    SPECIAL_ARTIFACT_TYPES = [
      :uninstall,
      :zap,
    ].freeze

    ARTIFACT_BLOCK_TYPES = [
      :preflight,
      :postflight,
      :uninstall_preflight,
      :uninstall_postflight,
    ].freeze

    DSL_METHODS = Set.new [
      :accessibility_access,
      :appcast,
      :artifacts,
      :auto_updates,
      :caskroom_path,
      :caveats,
      :conflicts_with,
      :container,
      :depends_on,
      :gpg,
      :homepage,
      :language,
      :name,
      :sha256,
      :staged_path,
      :url,
      :version,
      :appdir,
      *ORDINARY_ARTIFACT_TYPES,
      *ACTIVATABLE_ARTIFACT_TYPES,
      *SPECIAL_ARTIFACT_TYPES,
      *ARTIFACT_BLOCK_TYPES,
    ].freeze

    attr_reader :token
    def initialize(token)
      @token = token
    end

    def name(*args)
      @name ||= []
      return @name if args.empty?
      @name.concat(args.flatten)
    end

    def assert_only_one_stanza_allowed(stanza, arg_given)
      return unless instance_variable_defined?("@#{stanza}") && arg_given
      raise CaskInvalidError.new(token, "'#{stanza}' stanza may only appear once")
    end

    def homepage(homepage = nil)
      assert_only_one_stanza_allowed :homepage, !homepage.nil?
      @homepage ||= homepage
    end

    def language(*args, default: false, &block)
      if !args.empty? && block_given?
        @language_blocks ||= {}
        @language_blocks[args] = block

        return unless default

        unless @language_blocks.default.nil?
          raise CaskInvalidError.new(token, "Only one default language may be defined")
        end

        @language_blocks.default = block
      else
        language_eval
      end
    end

    def language_eval
      return @language if instance_variable_defined?(:@language)

      if @language_blocks.nil? || @language_blocks.empty?
        return @language = nil
      end

      MacOS.languages.map(&Locale.method(:parse)).each do |locale|
        key = @language_blocks.keys.detect do |strings|
          strings.any? { |string| locale.include?(string) }
        end

        next if key.nil?

        return @language = @language_blocks[key].call
      end

      @language = @language_blocks.default.call
    end

    def url(*args, &block)
      url_given = !args.empty? || block_given?
      return @url unless url_given
      assert_only_one_stanza_allowed :url, url_given
      @url ||= begin
        URL.from(*args, &block)
      rescue StandardError => e
        raise CaskInvalidError.new(token, "'url' stanza failed with: #{e}")
      end
    end

    def appcast(*args)
      return @appcast if args.empty?
      assert_only_one_stanza_allowed :appcast, !args.empty?
      @appcast ||= begin
        DSL::Appcast.new(*args) unless args.empty?
      rescue StandardError => e
        raise CaskInvalidError.new(token, e)
      end
    end

    def gpg(*args)
      return @gpg if args.empty?
      assert_only_one_stanza_allowed :gpg, !args.empty?
      @gpg ||= begin
        DSL::Gpg.new(*args) unless args.empty?
      rescue StandardError => e
        raise CaskInvalidError.new(token, e)
      end
    end

    def container(*args)
      return @container if args.empty?
      # TODO: remove this constraint, and instead merge multiple container stanzas
      assert_only_one_stanza_allowed :container, !args.empty?
      @container ||= begin
        DSL::Container.new(*args) unless args.empty?
      rescue StandardError => e
        raise CaskInvalidError.new(token, e)
      end
      # TODO: remove this backward-compatibility section after removing nested_container
      if @container && @container.nested
        artifacts[:nested_container] << @container.nested
      end
      @container
    end

    SYMBOLIC_VERSIONS = Set.new [
      :latest,
    ]

    def version(arg = nil)
      return @version if arg.nil?
      assert_only_one_stanza_allowed :version, !arg.nil?
      raise CaskInvalidError.new(token, "invalid 'version' value: '#{arg.inspect}'") if !arg.is_a?(String) && !SYMBOLIC_VERSIONS.include?(arg)
      @version ||= DSL::Version.new(arg)
    end

    SYMBOLIC_SHA256S = Set.new [
      :no_check,
    ]

    def sha256(arg = nil)
      return @sha256 if arg.nil?
      assert_only_one_stanza_allowed :sha256, !arg.nil?
      raise CaskInvalidError.new(token, "invalid 'sha256' value: '#{arg.inspect}'") if !arg.is_a?(String) && !SYMBOLIC_SHA256S.include?(arg)
      @sha256 ||= arg
    end

    def license(*)
      # TODO: Uncomment after `license` has been
      #       removed from all official taps.
      # odeprecated "Hbc::DSL#license"
    end

    # depends_on uses a load method so that multiple stanzas can be merged
    def depends_on(*args)
      return @depends_on if args.empty?
      @depends_on ||= DSL::DependsOn.new
      begin
        @depends_on.load(*args) unless args.empty?
      rescue RuntimeError => e
        raise CaskInvalidError.new(token, e)
      end
      @depends_on
    end

    def conflicts_with(*args)
      return @conflicts_with if args.empty?
      # TODO: remove this constraint, and instead merge multiple conflicts_with stanzas
      assert_only_one_stanza_allowed :conflicts_with, !args.empty?
      @conflicts_with ||= begin
        DSL::ConflictsWith.new(*args) unless args.empty?
      rescue StandardError => e
        raise CaskInvalidError.new(token, e)
      end
    end

    def artifacts
      @artifacts ||= Hash.new { |hash, key| hash[key] = Set.new }
    end

    def caskroom_path
      @caskroom_path ||= Hbc.caskroom.join(token)
    end

    def staged_path
      return @staged_path if @staged_path
      cask_version = version || :unknown
      @staged_path = caskroom_path.join(cask_version.to_s)
    end

    def caveats(*string, &block)
      @caveats ||= []
      if block_given?
        @caveats << Hbc::Caveats.new(block)
      elsif string.any?
        @caveats << string.map { |s| s.to_s.sub(/[\r\n \t]*\Z/, "\n\n") }
      end
      @caveats
    end

    def accessibility_access(accessibility_access = nil)
      assert_only_one_stanza_allowed :accessibility_access, !accessibility_access.nil?
      @accessibility_access ||= accessibility_access
    end

    def auto_updates(auto_updates = nil)
      assert_only_one_stanza_allowed :auto_updates, !auto_updates.nil?
      @auto_updates ||= auto_updates
    end

    ORDINARY_ARTIFACT_TYPES.each do |type|
      define_method(type) do |*args|
        if type == :stage_only && args != [true]
          raise CaskInvalidError.new(token, "'stage_only' takes a single argument: true")
        end
        artifacts[type] << args
        if artifacts.key?(:stage_only) && artifacts.keys.count > 1 &&
           !(artifacts.keys & ACTIVATABLE_ARTIFACT_TYPES).empty?
          raise CaskInvalidError.new(token, "'stage_only' must be the only activatable artifact")
        end
      end
    end

    def installer(*args)
      return artifacts[:installer] if args.empty?
      artifacts[:installer] << DSL::Installer.new(*args)
      raise "'stage_only' must be the only activatable artifact" if artifacts.key?(:stage_only)
    rescue StandardError => e
      raise CaskInvalidError.new(token, e)
    end

    SPECIAL_ARTIFACT_TYPES.each do |type|
      define_method(type) do |*args|
        artifacts[type].merge(args)
      end
    end

    ARTIFACT_BLOCK_TYPES.each do |type|
      define_method(type) do |&block|
        artifacts[type] << block
      end
    end

    def method_missing(method, *)
      if method
        Utils.method_missing_message(method, token)
        nil
      else
        super
      end
    end

    def respond_to_missing?(*)
      true
    end

    def appdir
      self.class.appdir
    end

    def self.appdir
      Hbc.appdir.sub(%r{\/$}, "")
    end
  end
end
