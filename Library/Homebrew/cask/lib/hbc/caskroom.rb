module Hbc
  module Caskroom
    module_function

    def migrate_caskroom_from_repo_to_prefix
      repo_caskroom = Hbc.homebrew_repository.join("Caskroom")
      return if Hbc.caskroom.exist?
      return unless repo_caskroom.directory?

      ohai "Moving Caskroom from HOMEBREW_REPOSITORY to HOMEBREW_PREFIX"

      if Hbc.caskroom.parent.writable?
        FileUtils.mv repo_caskroom, Hbc.caskroom
      else
        opoo "#{Hbc.caskroom.parent} is not writable, sudo is needed to move the Caskroom."
        sudo "/bin/mv", repo_caskroom.to_s, Hbc.caskroom.parent.to_s
      end
    end

    def ensure_caskroom_exists
      return if Hbc.caskroom.exist?

      ohai "Creating Caskroom at #{Hbc.caskroom}"
      ohai "We'll set permissions properly so we won't need sudo in the future"

      sudo "/bin/mkdir", "-p", Hbc.caskroom
      sudo "/bin/chmod", "g+rwx", Hbc.caskroom
      sudo "/usr/sbin/chown", Utils.current_user, Hbc.caskroom
      sudo "/usr/bin/chgrp", "admin", Hbc.caskroom
    end

    def sudo(*args)
      ohai "/usr/bin/sudo #{args.join(" ")}"
      system "/usr/bin/sudo", *args
    end
  end
end
