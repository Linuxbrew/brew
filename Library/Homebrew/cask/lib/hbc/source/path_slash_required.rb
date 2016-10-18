require "hbc/source/path_base"

module Hbc
  module Source
    class PathSlashRequired < PathBase
      def self.me?(query)
        path = path_for_query(query)
        path.to_s.include?("/") && path.exist?
      end
    end
  end
end
