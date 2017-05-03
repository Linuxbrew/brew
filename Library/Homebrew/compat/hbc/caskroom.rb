module Hbc
  module Caskroom
    module_function

    def migrate_legacy_caskroom
      return if Hbc.caskroom.exist?

      legacy_caskroom = Pathname.new("/opt/homebrew-cask/Caskroom")
      return if Hbc.caskroom == legacy_caskroom
      return unless legacy_caskroom.exist?
      return if legacy_caskroom.symlink?

      ohai "Migrating Caskroom from #{legacy_caskroom} to #{Hbc.caskroom}."
      if Hbc.caskroom.parent.writable?
        FileUtils.mv legacy_caskroom, Hbc.caskroom
      else
        opoo "#{Hbc.caskroom.parent} is not writable, sudo is needed to move the Caskroom."
        SystemCommand.run("/bin/mv", args: [legacy_caskroom, Hbc.caskroom.parent], sudo: true)
      end

      ohai "Creating symlink from #{Hbc.caskroom} to #{legacy_caskroom}."
      if legacy_caskroom.parent.writable?
        FileUtils.ln_s Hbc.caskroom, legacy_caskroom
      else
        opoo "#{legacy_caskroom.parent} is not writable, sudo is needed to link the Caskroom."
        SystemCommand.run("/bin/ln", args: ["-s", Hbc.caskroom, legacy_caskroom], sudo: true)
      end
    end

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
  end
end
