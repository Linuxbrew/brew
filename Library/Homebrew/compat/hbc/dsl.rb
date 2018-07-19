module Hbc
  class DSL
    module Compat
      def license(*)
        odisabled "Hbc::DSL#license"
      end
    end

    prepend Compat
  end
end
