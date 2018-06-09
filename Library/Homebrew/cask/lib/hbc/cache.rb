module Hbc
  module Cache
    module_function

    def path
      @path ||= HOMEBREW_CACHE.join("Cask")
    end
  end
end
