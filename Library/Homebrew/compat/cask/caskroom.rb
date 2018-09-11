module Cask
  module Caskroom
    class << self
      module Compat
        def migrate_legacy_caskroom
          return if path.exist?

          legacy_caskroom_path = Pathname.new("/opt/homebrew-cask/Caskroom")
          return if path == legacy_caskroom_path
          return unless legacy_caskroom_path.exist?
          return if legacy_caskroom_path.symlink?

          ohai "Migrating Caskroom from #{legacy_caskroom_path} to #{path}."
          if path.parent.writable?
            FileUtils.mv legacy_caskroom_path, path
          else
            opoo "#{path.parent} is not writable, sudo is needed to move the Caskroom."
            SystemCommand.run("/bin/mv", args: [legacy_caskroom_path, path.parent], sudo: true)
          end

          ohai "Creating symlink from #{path} to #{legacy_caskroom_path}."
          if legacy_caskroom_path.parent.writable?
            FileUtils.ln_s path, legacy_caskroom_path
          else
            opoo "#{legacy_caskroom_path.parent} is not writable, sudo is needed to link the Caskroom."
            SystemCommand.run("/bin/ln", args: ["-s", path, legacy_caskroom_path], sudo: true)
          end
        end

        def migrate_caskroom_from_repo_to_prefix
          repo_caskroom_path = HOMEBREW_REPOSITORY.join("Caskroom")
          return if path.exist?
          return unless repo_caskroom_path.directory?

          ohai "Moving Caskroom from HOMEBREW_REPOSITORY to HOMEBREW_PREFIX"

          if path.parent.writable?
            FileUtils.mv repo_caskroom_path, path
          else
            opoo "#{path.parent} is not writable, sudo is needed to move the Caskroom."
            SystemCommand.run("/bin/mv", args: [repo_caskroom_path, path.parent], sudo: true)
          end
        end
      end

      prepend Compat
    end
  end
end
