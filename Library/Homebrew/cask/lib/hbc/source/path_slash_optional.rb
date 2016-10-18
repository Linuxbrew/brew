require "hbc/source/path_base"

module Hbc
  module Source
    class PathSlashOptional < PathBase
      def self.me?(query)
        path = path_for_query(query)
        path.exist?
      end
    end
  end
end
