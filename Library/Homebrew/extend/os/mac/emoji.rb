module Emoji
  class << self
    def enabled?
      generic_enabled? && MacOS.version >= :lion
    end
  end
end
