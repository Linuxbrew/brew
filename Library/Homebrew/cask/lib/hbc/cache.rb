module Hbc
  module Cache
    module_function

    def ensure_cache_exists
      return if Hbc.cache.exist?

      odebug "Creating Cache at #{Hbc.cache}"
      Hbc.cache.mkpath
    end

    def delete_legacy_cache
      legacy_cache = HOMEBREW_CACHE.join("Casks")
      return unless legacy_cache.exist?

      ohai "Deleting legacy cache at #{legacy_cache}..."
      FileUtils.remove_entry_secure(legacy_cache)
    end
  end
end
