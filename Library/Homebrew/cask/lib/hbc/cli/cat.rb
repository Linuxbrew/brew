module Hbc
  class CLI
    class Cat < AbstractCommand
      def initialize(*)
        super
        raise CaskUnspecifiedError if args.empty?
      end

      def run
        raise CaskError, "Cat incomplete." if cat_casks == :incomplete
      end

      def cat_casks
        casks.each do |cask|
          puts File.open(cask.sourcefile_path, &:read)
        end
      end

      def self.help
        "dump raw source of the given Cask to the standard output"
      end
    end
  end
end
