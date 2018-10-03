require "utils/user"

module Cask
  module Caskroom
    module_function

    def path
      @path ||= HOMEBREW_PREFIX.join("Caskroom")
    end

    def ensure_caskroom_exists
      return if path.exist?

      sudo = !path.parent.writable?

      if sudo && !ENV.key?("SUDO_ASKPASS") && $stdout.tty?
        ohai "Creating Caskroom at #{path}"
        ohai "We'll set permissions properly so we won't need sudo in the future."
      end

      SystemCommand.run("/bin/mkdir", args: ["-p", path], sudo: sudo)
      SystemCommand.run("/bin/chmod", args: ["g+rwx", path], sudo: sudo)
      SystemCommand.run("/usr/sbin/chown", args: [User.current, path], sudo: sudo)
      SystemCommand.run("/usr/bin/chgrp", args: ["admin", path], sudo: sudo)
    end

    def casks
      return [] unless path.exist?

      Pathname.glob(path.join("*")).sort.select(&:directory?).map do |path|
        token = path.basename.to_s

        if tap_path = CaskLoader.tap_paths(token).first
          CaskLoader::FromTapPathLoader.new(tap_path).load
        elsif caskroom_path = Pathname.glob(path.join(".metadata/*/*/*/*.rb")).first
          CaskLoader::FromPathLoader.new(caskroom_path).load
        else
          CaskLoader.load(token)
        end
      end
    end
  end
end
