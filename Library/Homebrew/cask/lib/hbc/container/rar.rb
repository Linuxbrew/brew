require "hbc/container/base"

module Hbc
  class Container
    class Rar < Base
      def self.can_extract?(path:, magic_number:)
        magic_number.match?(/\ARar!/n)
      end

      def extract_to_dir(unpack_dir, basename:, verbose:)
        @command.run!("unrar",
                      args: ["x", "-inul", path, unpack_dir],
                      env: { "PATH" => PATH.new(Formula["unrar"].opt_bin, ENV["PATH"]) })
      end

      def dependencies
        @dependencies ||= [Formula["unrar"]]
      end
    end
  end
end
