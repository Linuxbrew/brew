module Hbc
  module Caskroom
    module_function

    def migrate_caskroom_from_repo_to_prefix
      repo_caskroom = HOMEBREW_REPOSITORY.join("Caskroom")
      return if Hbc.caskroom.exist?
      return unless repo_caskroom.directory?

      ohai "Moving Caskroom from HOMEBREW_REPOSITORY to HOMEBREW_PREFIX"

      if Hbc.caskroom.parent.writable?
        FileUtils.mv repo_caskroom, Hbc.caskroom
      else
        opoo "#{Hbc.caskroom.parent} is not writable, sudo is needed to move the Caskroom."
        SystemCommand.run("/bin/mv", args: [repo_caskroom, Hbc.caskroom.parent], sudo: true)
      end
    end

    def ensure_caskroom_exists
      return if Hbc.caskroom.exist?

      ohai "Creating Caskroom at #{Hbc.caskroom}"
      ohai "We'll set permissions properly so we won't need sudo in the future"
      sudo = !Hbc.caskroom.parent.writable?

      SystemCommand.run("/bin/mkdir", args: ["-p", Hbc.caskroom], sudo: sudo)
      SystemCommand.run("/bin/chmod", args: ["g+rwx", Hbc.caskroom], sudo: sudo)
      SystemCommand.run("/usr/sbin/chown", args: [Utils.current_user, Hbc.caskroom], sudo: sudo)
      SystemCommand.run("/usr/bin/chgrp", args: ["admin", Hbc.caskroom], sudo: sudo)
    end
  end
end
