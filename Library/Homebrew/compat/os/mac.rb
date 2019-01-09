module OS
  module Mac
    class << self
      module Compat
        def prefer_64_bit?
          odeprecated("MacOS.prefer_64_bit?")
          Hardware::CPU.is_64_bit?
        end
      end

      prepend Compat
    end
  end
end
