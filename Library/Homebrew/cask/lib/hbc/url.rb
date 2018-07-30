module Hbc
  class URL
    attr_reader :using, :revision, :trust_cert, :uri, :cookies, :referer, :data, :user_agent

    extend Forwardable
    def_delegators :uri, :path, :scheme, :to_s


    def initialize(uri, options = {})
      @uri        = URI(uri)
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
