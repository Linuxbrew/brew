require "hbc/container/base"

module Hbc
  class Container
    class Cab < Base
      def self.can_extract?(path:, magic_number:)
        magic_number.match?(/\A(MSCF|MZ)/n)
      end

      def extract_to_dir(unpack_dir, basename:)
        @command.run!("cabextract",
                      args: ["-d", unpack_dir, "--", path],
                      env: { "PATH" => PATH.new(Formula["cabextract"].opt_bin, ENV["PATH"]) })
      end

      def dependencies
        @dependencies ||= [Formula["cabextract"]]
      end
    end
  end
end
