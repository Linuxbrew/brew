module Hbc
  class URL
    attr_reader :using, :revision, :trust_cert, :uri, :cookies, :referer, :data, :user_agent

    extend Forwardable
    def_delegators :uri, :path, :scheme, :to_s

    def self.from(*args, &block)
      if block_given?
        Hbc::DSL::StanzaProxy.once(self) { new(*block.call) }
      else
        new(*args)
      end
    end

    def initialize(uri, options = {})
      @uri        = Hbc::UnderscoreSupportingURI.parse(uri)
      @user_agent = options.fetch(:user_agent, :default)
      @cookies    = options[:cookies]
      @referer    = options[:referer]
      @using      = options[:using]
      @revision   = options[:revision]
      @trust_cert = options[:trust_cert]
      @data       = options[:data]
    end
  end
end
