module Hbc
  module Cache
    module_function

    def ensure_cache_exists
      return if Hbc.cache.exist?

      odebug "Creating Cache at #{Hbc.cache}"
      Hbc.cache.mkpath
    end
  end
end
