module Language
  module Haskell
    module Cabal
      def cabal_clean_lib
        odeprecated "Language::Haskell::Cabal#cabal_clean_lib"
        rm_rf lib
      end
    end
  end
end
