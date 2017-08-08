module CaskLoaderCompatibilityLayer
  private

  def cask(header_token, **options, &block)
    if header_token.is_a?(Hash) && header_token.key?(:v1)
      odeprecated %q("cask :v1 => 'token'"), %q("cask 'token'")
      header_token = header_token[:v1]
    end

    super(header_token, **options, &block)
  end
end

module Hbc
  module CaskLoader
    class FromContentLoader; end

    class FromPathLoader < FromContentLoader
      prepend CaskLoaderCompatibilityLayer
    end
  end
end
