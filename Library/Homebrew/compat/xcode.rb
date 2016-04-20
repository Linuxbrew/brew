module OS
  module Mac
    module Xcode
      extend self

      def provides_autotools?
        version < "4.3"
      end
    end
  end
end
