module Cachable
  def cache
    @cache ||= {}
  end

  def clear_cache
    cache.clear
  end
end
