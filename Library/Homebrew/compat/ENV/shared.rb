module SharedEnvExtension
  module Compat
    def j1
      odisabled "ENV.j1", "ENV.deparallelize"
    end

    def java_cache
      odisabled "ENV.java_cache"
    end
  end

  prepend Compat
end
