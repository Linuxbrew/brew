require "hbc/artifact/symlinked"

module Hbc
  module Artifact
    class Binary < Symlinked
      def link
        super
        return if source.executable?
        if source.writable?
          FileUtils.chmod "+x", source
        else
          @command.run!("/bin/chmod", args: ["+x", source], sudo: true)
        end
      end
    end
  end
end
