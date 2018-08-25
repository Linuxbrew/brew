module UpdateMigrator
  module_function

  def migrate_legacy_repository_if_necessary
    return unless HOMEBREW_PREFIX.to_s == "/usr/local"
    return unless HOMEBREW_REPOSITORY.to_s == "/usr/local"

    ohai "Migrating HOMEBREW_REPOSITORY (please wait)..."

    unless HOMEBREW_PREFIX.writable_real?
      ofail <<~EOS
        #{HOMEBREW_PREFIX} is not writable.

        You should change the ownership and permissions of #{HOMEBREW_PREFIX}
        temporarily back to your user account so we can complete the Homebrew
        repository migration:
          sudo chown -R $(whoami) #{HOMEBREW_PREFIX}
      EOS
      return
    end

    new_homebrew_repository = Pathname.new "/usr/local/Homebrew"
    new_homebrew_repository.rmdir_if_possible
    if new_homebrew_repository.exist?
      ofail <<~EOS
        #{new_homebrew_repository} already exists.
        Please remove it manually or uninstall and reinstall Homebrew into a new
        location as the migration cannot be done automatically.
      EOS
      return
    end
    new_homebrew_repository.mkpath

    repo_files = HOMEBREW_REPOSITORY.cd do
      Utils.popen_read("git ls-files").lines.map(&:chomp)
    end

    unless Utils.popen_read("git status --untracked-files=all --porcelain").empty?
      HOMEBREW_REPOSITORY.cd do
        quiet_system "git", "merge", "--abort"
        quiet_system "git", "rebase", "--abort"
        quiet_system "git", "reset", "--mixed"
        safe_system "git", "-c", "user.email=brew-update@localhost",
                           "-c", "user.name=brew update",
                           "stash", "save", "--include-untracked"
      end
      stashed = true
    end

    FileUtils.cp_r "#{HOMEBREW_REPOSITORY}/.git", "#{new_homebrew_repository}/.git"
    new_homebrew_repository.cd do
      safe_system "git", "checkout", "--force", "."
      safe_system "git", "stash", "pop" if stashed
    end

    if (HOMEBREW_REPOSITORY/"Library/Locks").exist?
      FileUtils.cp_r "#{HOMEBREW_REPOSITORY}/Library/Locks", "#{new_homebrew_repository}/Library/Locks"
    end

    if (HOMEBREW_REPOSITORY/"Library/Taps").exist?
      FileUtils.cp_r "#{HOMEBREW_REPOSITORY}/Library/Taps", "#{new_homebrew_repository}/Library/Taps"
    end

    unremovable_paths = []
    extra_remove_paths = [".git", "Library/Locks", "Library/Taps",
                          "Library/Homebrew/cask", "Library/Homebrew/test"]
    (repo_files + extra_remove_paths).each do |file|
      path = Pathname.new "#{HOMEBREW_REPOSITORY}/#{file}"
      begin
        FileUtils.rm_rf path
      rescue Errno::EACCES
        unremovable_paths << path
      end
      quiet_system "rmdir", "-p", path.parent if path.parent.exist?
    end

    unless unremovable_paths.empty?
      ofail <<~EOS
        Could not remove old HOMEBREW_REPOSITORY paths!
        Please do this manually with:
          sudo rm -rf #{unremovable_paths.join " "}
      EOS
    end

    (Keg::ALL_TOP_LEVEL_DIRECTORIES + ["Cellar"]).each do |dir|
      FileUtils.mkdir_p "#{HOMEBREW_PREFIX}/#{dir}"
    end

    src = Pathname.new("#{new_homebrew_repository}/bin/brew")
    dst = Pathname.new("#{HOMEBREW_PREFIX}/bin/brew")
    begin
      FileUtils.ln_s(src.relative_path_from(dst.parent), dst)
    rescue Errno::EACCES, Errno::ENOENT
      ofail <<~EOS
        Could not create symlink at #{dst}!
        Please do this manually with:
          sudo ln -sf #{src} #{dst}
          sudo chown $(whoami) #{dst}
      EOS
    end

    link_completions_manpages_and_docs(new_homebrew_repository)

    ohai "Migrated HOMEBREW_REPOSITORY to #{new_homebrew_repository}!"
    puts <<~EOS
      Homebrew no longer needs to have ownership of /usr/local. If you wish you can
      return /usr/local to its default ownership with:
        sudo chown root:wheel #{HOMEBREW_PREFIX}
    EOS
  rescue => e
    ofail <<~EOS
      #{Tty.bold}Failed to migrate HOMEBREW_REPOSITORY to #{new_homebrew_repository}!#{Tty.reset}
      The error was:
        #{e}
      Please try to resolve this error yourself and then run `brew update` again to
      complete the migration. If you need help please +1 an existing error or comment
      with your new error in issue:
        #{Formatter.url("https://github.com/Homebrew/brew/issues/987")}
    EOS
    $stderr.puts e.backtrace
  end
end
