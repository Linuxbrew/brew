require "hbc/container/naked"

module Hbc
  class Container
    class Pkg < Naked
      def self.me?(criteria)
        criteria.extension(%r{m?pkg$}) &&
          (criteria.path.directory? ||
           criteria.magic_number(%r{^xar!}n))
      end
    end
  end
end
