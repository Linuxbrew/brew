module Hbc
  class DSL
    module Compat
      def license(*)
        odeprecated "Hbc::DSL#license"
      end
    end

    prepend Compat
  end
end
