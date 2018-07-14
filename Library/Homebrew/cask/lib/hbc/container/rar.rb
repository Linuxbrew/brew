require "hbc/container/generic_unar"

module Hbc
  class Container
    class Rar
      def self.me?(criteria)
        criteria.magic_number(/\ARar!/n) &&
          super
      end

      def extract
        path = @path
        unpack_dir = @cask.staged_path
        @command.run!(Formula["unrar"].opt_bin/"unrar", args: ["x", "-inul", path, unpack_dir])
      end

      def dependencies
        @dependencies ||= [Formula["unrar"]]
      end
    end
  end
end
