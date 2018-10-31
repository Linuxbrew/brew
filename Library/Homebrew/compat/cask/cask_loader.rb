module Cask
  module CaskLoader
    class FromContentLoader; end

    class FromPathLoader < FromContentLoader
      module Compat
        private

        # TODO: can't delete this code until the merge of
        # https://github.com/Homebrew/brew/pull/4730 or an equivalent.
        def cask(header_token, **options, &block)
          if header_token.is_a?(Hash) && header_token.key?(:v1)
            odisabled %q("cask :v1 => 'token'"), %q("cask 'token'")
            header_token = header_token[:v1]
          end

          super(header_token, **options, &block)
        end
      end

      prepend Compat
    end
  end
end
