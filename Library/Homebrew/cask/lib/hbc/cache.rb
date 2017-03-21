module Hbc
  module Cache
    module_function

    def ensure_cache_exists
      return if Hbc.cache.exist?

      odebug "Creating Cache at #{Hbc.cache}"
      Hbc.cache.mkpath
    end

    def delete_legacy_cache
      return unless Hbc.legacy_cache.exist?

      ohai "Deleting legacy cache at #{Hbc.legacy_cache}..."
      FileUtils.remove_entry_secure(Hbc.legacy_cache)
    end
  end
end
