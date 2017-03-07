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
  end
end
