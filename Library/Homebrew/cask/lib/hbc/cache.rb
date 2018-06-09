module Hbc
  module Cache
    module_function

    def path
      @path ||= HOMEBREW_CACHE.join("Cask")
    end

    def ensure_cache_exists
      return if path.exist?

      odebug "Creating Cache at #{path}"
      path.mkpath
    end
  end
end
