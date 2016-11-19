module CaskLoaderCompatibilityLayer
  private

  def build_cask(header_token, &block)
    if header_token.is_a?(Hash) && header_token.key?(:v1)
      odeprecated %q("cask :v1 => 'token'"), %q("cask 'token'")
      header_token = header_token[:v1]
    end

    super(header_token, &block)
  end
end

module Hbc
  class CaskLoader
    prepend CaskLoaderCompatibilityLayer
  end
end
