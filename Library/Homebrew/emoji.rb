module Emoji
  class << self
    def tick
      # necessary for 1.8.7 unicode handling since many installs are on 1.8.7
      @tick ||= ["2714".hex].pack("U*")
    end

    def cross
      # necessary for 1.8.7 unicode handling since many installs are on 1.8.7
      @cross ||= ["2718".hex].pack("U*")
    end

    def install_badge
      ENV["HOMEBREW_INSTALL_BADGE"] || "\xf0\x9f\x8d\xba"
    end

    def enabled?
      !ENV["HOMEBREW_NO_EMOJI"]
    end
    alias generic_enabled? enabled?
  end
end

require "extend/os/emoji"
