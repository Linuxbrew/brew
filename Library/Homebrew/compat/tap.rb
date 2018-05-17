module CaskTapMigration
  def initialize(user, repo)
    super

    return unless user == "caskroom"

    # TODO: Remove this check after migration.
    return unless repo == "tap-migration-test"

    new_user = "Homebrew"
    new_repo = (repo == "cask") ? repo : "cask-#{repo}"

    old_name = name
    old_path = path
    old_remote = path.git_origin

    super(new_user, new_repo)

    return unless old_path.git?

    new_name = name
    new_path = path
    new_remote = default_remote

    ohai "Migrating tap #{old_name} to #{new_name}..." if $stdout.tty?

    puts "Moving #{old_path} to #{new_path}..." if $stdout.tty?
    path.dirname.mkpath
    FileUtils.mv old_path, new_path

    puts "Changing remote from #{old_remote} to #{new_remote}..." if $stdout.tty?
    new_path.git_origin = new_remote
  end
end

class Tap
  prepend CaskTapMigration
end
