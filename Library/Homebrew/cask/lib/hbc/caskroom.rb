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
        system "/usr/bin/sudo", "--", "/bin/mv", "--", repo_caskroom.to_s, Hbc.caskroom.parent.to_s
      end
    end

    def ensure_caskroom_exists
      return if Hbc.caskroom.exist?

      ohai "Creating Caskroom at #{Hbc.caskroom}"
      if Hbc.caskroom.parent.writable?
        Hbc.caskroom.mkpath
      else
        ohai "We'll set permissions properly so we won't need sudo in the future"
        toplevel_dir = Hbc.caskroom
        toplevel_dir = toplevel_dir.parent until toplevel_dir.parent.root?
        unless toplevel_dir.directory?
          # If a toplevel dir such as '/opt' must be created, enforce standard permissions.
          # sudo in system is rude.
          system "/usr/bin/sudo", "--", "/bin/mkdir", "--",         toplevel_dir
          system "/usr/bin/sudo", "--", "/bin/chmod", "--", "0775", toplevel_dir
        end
        # sudo in system is rude.
        system "/usr/bin/sudo", "--", "/bin/mkdir", "-p", "--", Hbc.caskroom
        unless Hbc.caskroom.parent == toplevel_dir
          system "/usr/bin/sudo", "--", "/usr/sbin/chown", "-R", "--", "#{Utils.current_user}:staff", Hbc.caskroom.parent.to_s
        end
      end
    end
  end
end
