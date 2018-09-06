module Cask
  module Cache
    class << self
      module Compat
        def delete_legacy_cache
          legacy_cache = HOMEBREW_CACHE.join("Casks")
          return unless legacy_cache.exist?

          ohai "Deleting legacy cache at #{legacy_cache}"
          FileUtils.remove_entry_secure(legacy_cache)
        end
      end

      prepend Compat
    end
  end
end
