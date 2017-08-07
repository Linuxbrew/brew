module Hbc
  module CaskLoader
    class FromContentLoader
      attr_reader :content

      def initialize(content)
        @content = content
      end

      def load
        instance_eval(content.force_encoding("UTF-8"), __FILE__, __LINE__)
      end

      private

      def cask(header_token, **options, &block)
        Cask.new(header_token, **options, &block)
      end
    end

    class FromPathLoader < FromContentLoader
      def self.can_load?(ref)
        path = Pathname(ref)
        path.extname == ".rb" && path.expand_path.exist?
      end

      attr_reader :token, :path

      def initialize(path)
        path = Pathname(path).expand_path

        @token = path.basename(".rb").to_s
        @path = path
      end

      def load
        raise CaskUnavailableError.new(token, "'#{path}' does not exist.")  unless path.exist?
        raise CaskUnavailableError.new(token, "'#{path}' is not readable.") unless path.readable?
        raise CaskUnavailableError.new(token, "'#{path}' is not a file.")   unless path.file?

        @content = IO.read(path)

        super
      end

      private

      def cask(header_token, **options, &block)
        if token != header_token
          raise CaskTokenMismatchError.new(token, header_token)
        end

        super(header_token, **options, sourcefile_path: path, &block)
      end
    end

    class FromURILoader < FromPathLoader
      def self.can_load?(ref)
        ref.to_s.match?(::URI.regexp)
      end

      attr_reader :url

      def initialize(url)
        @url = URI(url)
        super Hbc.cache/File.basename(@url.path)
      end

      def load
        path.dirname.mkpath

        begin
          ohai "Downloading #{url}."
          curl_download url, to: path
        rescue ErrorDuringExecution
          raise CaskUnavailableError.new(token, "Failed to download #{Formatter.url(url)}.")
        end

        super
      end
    end

    class FromTapPathLoader < FromPathLoader
      def self.can_load?(ref)
        ref.to_s.match?(HOMEBREW_TAP_PATH_REGEX) && super
      end

      attr_reader :tap

      def initialize(tap_path)
        @tap = Tap.from_path(tap_path)
        super tap_path
      end

      private

      def cask(*args, &block)
        super(*args, tap: tap, &block)
      end
    end

    class FromTapLoader < FromTapPathLoader
      def self.can_load?(ref)
        ref.to_s.match?(HOMEBREW_TAP_CASK_REGEX)
      end

      def initialize(tapped_name)
        user, repo, token = tapped_name.split("/", 3)
        super Tap.fetch(user, repo).cask_dir/"#{token}.rb"
      end

      def load
        tap.install unless tap.installed?

        super
      end
    end

    class NullLoader < FromPathLoader
      def self.can_load?(*)
        true
      end

      def initialize(ref)
        token = File.basename(ref, ".rb")
        super CaskLoader.default_path(token)
      end

      def load
        raise CaskUnavailableError.new(token, "No Cask with this name exists.")
      end
    end

    def self.load_from_file(path)
      FromPathLoader.new(path).load
    end

    def self.load_from_string(content)
      FromContentLoader.new(content).load
    end

    def self.path(ref)
      self.for(ref).path
    end

    def self.load(ref)
      self.for(ref).load
    end

    def self.for(ref)
      [
        FromURILoader,
        FromTapLoader,
        FromTapPathLoader,
        FromPathLoader,
      ].each do |loader_class|
        return loader_class.new(ref) if loader_class.can_load?(ref)
      end

      if FromTapPathLoader.can_load?(default_path(ref))
        return FromTapPathLoader.new(default_path(ref))
      end

      case (possible_tap_casks = tap_paths(ref)).count
      when 1
        return FromTapPathLoader.new(possible_tap_casks.first)
      when 2..Float::INFINITY
        loaders = possible_tap_casks.map(&FromTapPathLoader.method(:new))

        raise CaskError, <<-EOS.undent
          Cask #{ref} exists in multiple taps:
          #{loaders.map { |loader| "  #{loader.tap}/#{loader.token}" }.join("\n")}
        EOS
      end

      possible_installed_cask = Cask.new(ref)
      if possible_installed_cask.installed?
        return FromPathLoader.new(possible_installed_cask.installed_caskfile)
      end

      NullLoader.new(ref)
    end

    def self.default_path(token)
      Hbc.default_tap.cask_dir/"#{token.to_s.downcase}.rb"
    end

    def self.tap_paths(token)
      Tap.map { |t| t.cask_dir/"#{token.to_s.downcase}.rb" }
         .select(&:exist?)
    end
  end
end
