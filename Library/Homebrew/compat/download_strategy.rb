class AbstractFileDownloadStrategy
  # TODO: This can be removed after a month because downloads
  #       will be outdated anyways at that point.
  module Compat
    def initialize(url, name, version, **meta)
      super

      old_cached_location = @cache/"#{name}-#{version}#{ext}"

      return unless old_cached_location.exist?
      FileUtils.mv old_cached_location, cached_location, force: true
    end
  end

  prepend Compat
end
