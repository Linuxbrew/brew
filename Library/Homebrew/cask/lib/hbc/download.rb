require "fileutils"
require "hbc/quarantine"
require "hbc/verify"

module Hbc
  class Download
    attr_reader :cask

    def initialize(cask, force: false, quarantine: true)
      @cask = cask
      @force = force
      @quarantine = quarantine
    end

    def perform
      clear_cache
      fetch
      quarantine
      downloaded_path
    end

    private

    attr_reader :force
    attr_accessor :downloaded_path

    def downloader
      @downloader ||= begin
        strategy = DownloadStrategyDetector.detect(cask.url.to_s, cask.url.using)
        strategy.new(cask.url.to_s, cask.token, cask.version, cache: Cache.path, **cask.url.specs)
      end
    end

    def clear_cache
      downloader.clear_cache if force || cask.version.latest?
    end

    def fetch
      downloader.fetch
      @downloaded_path = downloader.cached_location
    rescue StandardError => e
      raise CaskError, "Download failed on Cask '#{cask}' with message: #{e}"
    end

    def quarantine
      return unless @quarantine
      return unless Quarantine.available?
      return if Quarantine.detect(@downloaded_path)

      Quarantine.cask(cask: @cask, download_path: @downloaded_path)
    end
  end
end
