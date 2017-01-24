module Emoji
  class << self
    def install_badge
      ENV["HOMEBREW_INSTALL_BADGE"] || "🍺"
    end

    def enabled?
      !ENV["HOMEBREW_NO_EMOJI"]
    end
    alias generic_enabled? enabled?
  end
end

require "extend/os/emoji"
