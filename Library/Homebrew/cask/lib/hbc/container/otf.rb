require "hbc/container/naked"

module Hbc
  class Container
    class Otf < Naked
      def self.me?(criteria)
        criteria.magic_number(/\AOTTO/n)
      end
    end
  end
end
