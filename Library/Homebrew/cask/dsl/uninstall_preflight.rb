require "cask/staged"

module Hbc
  class DSL
    class UninstallPreflight < Base
      include Staged
    end
  end
end
