class Tap
  module Compat
    def initialize(user, repo)
      super

      return unless user == "caskroom"

      old_initial_revision_var = "HOMEBREW_UPDATE_BEFORE#{repo_var}"
      old_current_revision_var = "HOMEBREW_UPDATE_AFTER#{repo_var}"

      new_user = "Homebrew"
      new_repo = (repo == "cask") ? repo : "cask-#{repo}"

      old_name = name
      old_path = path
      old_remote = path.git_origin

      clear_cache
      super(new_user, new_repo)

      return unless old_path.directory?

      new_initial_revision_var = "HOMEBREW_UPDATE_BEFORE#{repo_var}"
      new_current_revision_var = "HOMEBREW_UPDATE_AFTER#{repo_var}"

      ENV[new_initial_revision_var] ||= ENV[old_initial_revision_var]
      ENV[new_current_revision_var] ||= ENV[old_current_revision_var]

      new_name = name
      new_path = path
      new_remote = default_remote

      ohai "Migrating tap #{old_name} to #{new_name}..." if $stdout.tty?

      if old_path.git?
        puts "Changing remote from #{old_remote} to #{new_remote}..." if $stdout.tty?
        old_path.git_origin = new_remote
      end

      puts "Moving #{old_path} to #{new_path}..." if $stdout.tty?
      path.dirname.mkpath
      FileUtils.mv old_path, new_path
    end
  end

  prepend Compat
end
