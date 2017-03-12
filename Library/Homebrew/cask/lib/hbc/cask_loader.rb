module Hbc
  module CaskLoader
    class FromContentLoader
      def initialize(content)
        @content = content
      end

      def load
        instance_eval(@content.force_encoding("UTF-8"), __FILE__, __LINE__)
      end

      private

      def cask(header_token, &block)
        Cask.new(header_token, &block)
      end
    end

    class FromPathLoader < FromContentLoader
      def self.can_load?(ref)
        path = Pathname.new(ref)
        path.extname == ".rb" && path.expand_path.exist?
      end

      attr_reader :token, :path

      def initialize(path)
        path = Pathname.new(path).expand_path

        @token = path.basename(".rb").to_s
        @path = path
      end

      def load
        raise CaskError, "'#{@path}' does not exist."  unless @path.exist?
        raise CaskError, "'#{@path}' is not readable." unless @path.readable?
        raise CaskError, "'#{@path}' is not a file."   unless @path.file?

        @content = IO.read(@path)

        super
      end

      private

      def cask(header_token, &block)
        if @token != header_token
          raise CaskTokenDoesNotMatchError.new(@token, header_token)
        end

        Cask.new(header_token, sourcefile_path: @path, &block)
      end
    end

    class FromURILoader < FromPathLoader
      def self.can_load?(ref)
        !(ref.to_s !~ ::URI.regexp)
      end

      def initialize(url)
        @url = url
        uri = URI(url)
        super Hbc.cache/File.basename(uri.path)
      end

      def load
        Hbc.cache.mkpath
        FileUtils.rm_f @path

        begin
          ohai "Downloading #{@url}."
          curl @url, "-o", @path
        rescue ErrorDuringExecution
          raise CaskUnavailableError, @url
        end

        super
      end
    end

    class FromTapLoader < FromPathLoader
      def self.can_load?(ref)
        !(ref.to_s !~ HOMEBREW_TAP_CASK_REGEX)
      end

      def initialize(tapped_name)
        user, repo, token = tapped_name.split("/", 3).map(&:downcase)
        @tap = Tap.fetch(user, repo)

        super @tap.cask_dir/"#{token}.rb"
      end

      def load
        @tap.install unless @tap.installed?

        super
      end
    end

    class NullLoader < FromPathLoader
      def self.can_load?(*)
        true
      end

      def initialize(ref)
        @token = File.basename(ref, ".rb")
        super CaskLoader.default_path(@token)
      end

      def load
        raise CaskUnavailableError, @token
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
        FromPathLoader,
      ].each do |loader_class|
        return loader_class.new(ref) if loader_class.can_load?(ref)
      end

      if FromPathLoader.can_load?(default_path(ref))
        return FromPathLoader.new(default_path(ref))
      end

      possible_tap_casks = tap_paths(ref)
      if possible_tap_casks.count == 1
        possible_tap_cask = possible_tap_casks.first
        return FromPathLoader.new(possible_tap_cask)
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
