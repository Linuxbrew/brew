module Cask
  class DSL
    module Compat
      # TODO: can't delete this code until the merge of
      # https://github.com/Homebrew/brew/pull/4730 or an equivalent.

      def gpg(*)
        odisabled "the `gpg` stanza"
      end

      def license(*)
        odisabled "the `license` stanza"
      end

      def accessibility_access(*)
        odisabled "the `accessibility_access` stanza"
      end
    end

    prepend Compat
  end
end
