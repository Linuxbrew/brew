require "fileutils"
require "hbc/verify"

module Hbc
  class Download
    attr_reader :cask

    def initialize(cask, force: false)
      @cask = cask
      @force = force
    end

    def perform
      clear_cache
      fetch
      downloaded_path
    end

    private

    attr_reader :force
    attr_accessor :downloaded_path

    def downloader
      @downloader ||= case cask.url.using
      when :svn
        SubversionDownloadStrategy.new(cask)
      when :post
        CurlPostDownloadStrategy.new(cask)
      else
        CurlDownloadStrategy.new(cask)
      end
    end

    def clear_cache
      downloader.clear_cache if force || cask.version.latest?
    end

    def fetch
      self.downloaded_path = downloader.fetch
    rescue StandardError => e
      raise CaskError, "Download failed on Cask '#{cask}' with message: #{e}"
    end
  end
end
