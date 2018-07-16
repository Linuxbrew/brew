require "hbc/container/base"

module Hbc
  class Container
    class Cab < Base
      def self.can_extract?(path:, magic_number:)
        magic_number.match?(/\A(MSCF|MZ)/n)
      end

      def extract
        Dir.mktmpdir do |unpack_dir|
          @command.run!("cabextract",
                        args: ["-d", unpack_dir, "--", @path],
                        env: { "PATH" => PATH.new(Formula["cabextract"].opt_bin, ENV["PATH"]) })
          @command.run!("/usr/bin/ditto", args: ["--", unpack_dir, @cask.staged_path])
        end
      end

      def dependencies
        @dependencies ||= [Formula["cabextract"]]
      end
    end
  end
end
