module Hbc
  class FakeFetcher
    def self.fake_response_for(url, response)
      @responses[url] = response
    end

    def self.head(url)
      @responses ||= {}
      raise("no response faked for #{url.inspect}") unless @responses.key?(url)
      @responses[url]
    end

    def self.init
      @responses = {}
    end

    def self.clear
      @responses = {}
    end
  end
end

module FakeFetcherHooks
  def before_setup
    super
    Hbc::FakeFetcher.init
  end

  def after_teardown
    super
    Hbc::FakeFetcher.clear
  end
end

module MiniTest
  class Spec
    include FakeFetcherHooks
  end
end
