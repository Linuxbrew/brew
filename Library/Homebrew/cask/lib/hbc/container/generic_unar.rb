require "hbc/container/base"

module Hbc
  class Container
    class GenericUnar < Base
      def self.can_extract?(path:, magic_number:)
        false
      end

      def extract_to_dir(unpack_dir, basename:)
        @command.run!("unar",
                      args: ["-force-overwrite", "-quiet", "-no-directory", "-output-directory", unpack_dir, "--", path],
                      env: { "PATH" => PATH.new(Formula["unar"].opt_bin, ENV["PATH"]) })
      end

      def dependencies
        @dependencies ||= [Formula["unar"]]
      end
    end
  end
end
