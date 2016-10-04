module OS
  module Mac
    module Xcode
      module_function

      def provides_autotools?
        odeprecated "OS::Mac::Xcode.provides_autotools?"
        version < "4.3"
      end
    end
  end
end
