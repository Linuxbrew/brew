require "hbc/container/base"

module Hbc
  class Container
    class GenericUnar < Base
      def self.me?(_criteria)
        false
      end

      def extract
        unpack_dir = @cask.staged_path

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
