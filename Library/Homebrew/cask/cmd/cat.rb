module Cask
  class Cmd
    class Cat < AbstractCommand
      def initialize(*)
        super
        raise CaskUnspecifiedError if args.empty?
      end

      def run
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
