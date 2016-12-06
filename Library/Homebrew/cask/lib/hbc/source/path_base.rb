require "rubygems"
require "hbc/cask_loader"

module Hbc
  module Source
    class PathBase
      # derived classes must define method self.me?

      def self.path_for_query(query)
        Pathname.new(query).sub(/(\.rb)?$/, ".rb")
      end

      attr_reader :path

      def initialize(path)
        @path = Pathname.new(path).expand_path
      end

      def load
        CaskLoader.load_from_file(@path)
      end

      def to_s
        # stringify to fully-resolved location
        @path.to_s
      end
    end
  end
end
