require "hbc/container/naked"

module Hbc
  class Container
    class Pkg < Naked
      def self.can_extract?(path:, magic_number:)
        path.extname.match?(/\A.m?pkg\Z/) &&
          (path.directory? || magic_number.match?(/\Axar!/n))
      end
    end
  end
end
