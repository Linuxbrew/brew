module OS
  module Mac
    class << self
      module Compat
        def release
          odisabled "MacOS.release", "MacOS.version"
          version
        end
      end

      prepend Compat
    end
  end
end
