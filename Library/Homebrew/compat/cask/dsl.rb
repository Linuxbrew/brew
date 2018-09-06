module Cask
  class DSL
    module Compat
      def gpg(*)
        odeprecated "the `gpg` stanza", disable_on: Time.new(2018, 12, 31)
      end

      def license(*)
        odisabled "the `license` stanza"
      end
    end

    prepend Compat
  end
end
