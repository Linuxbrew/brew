module Hbc
  module Cache
    module_function

    def path
      @path ||= HOMEBREW_CACHE/"Cask"
    end
  end
end
