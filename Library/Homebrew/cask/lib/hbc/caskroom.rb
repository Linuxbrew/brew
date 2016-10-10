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
        command "/bin/mv", repo_caskroom, Hbc.caskroom.parent, :use_sudo => true
      end
    end

    def ensure_caskroom_exists
      return if Hbc.caskroom.exist?

      ohai "Creating Caskroom at #{Hbc.caskroom}"
      ohai "We'll set permissions properly so we won't need sudo in the future"
      use_sudo = !Hbc.caskroom.parent.writable?

      command "/bin/mkdir", "-p", Hbc.caskroom, :use_sudo => use_sudo
      command "/bin/chmod", "g+rwx", Hbc.caskroom, :use_sudo => use_sudo
      command "/usr/sbin/chown", Utils.current_user, Hbc.caskroom, :use_sudo => use_sudo
      command "/usr/bin/chgrp", "admin", Hbc.caskroom, :use_sudo => use_sudo
    end

    def command(*args)
      options = args.last.is_a?(Hash) ? args.pop : {}

      if options[:use_sudo]
        args.unshift "/usr/bin/sudo"
      end

      ohai args.join(" ")
      system *args
    end
  end
end
