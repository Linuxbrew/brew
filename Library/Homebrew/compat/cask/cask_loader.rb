module Cask
  module CaskLoader
    class FromContentLoader; end

    class FromPathLoader < FromContentLoader
      module Compat
        private

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
