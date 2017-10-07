require "hbc/container/directory"

module Hbc
  class Container
    class SvnRepository < Directory
      def self.me?(criteria)
        criteria.path.join(".svn").directory?
      end

      def skip_path?(path)
        path.basename.to_s == ".svn"
      end
    end
  end
end
