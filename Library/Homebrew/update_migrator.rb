require "cask/cask_loader"
require "cask/download"

module UpdateMigrator
  class << self
    def formula_resources(formula)
      specs = [formula.stable, formula.devel, formula.head].compact

      [*formula.bottle&.resource] + specs.flat_map do |spec|
        [
          spec,
          *spec.resources.values,
          *spec.patches.select(&:external?).map(&:resource),
        ]
      end
    end
    private :formula_resources

    def parse_extname(url)
      uri_path = if URI::DEFAULT_PARSER.make_regexp =~ url
        uri = URI(url)
        uri.query ? "#{uri.path}?#{uri.query}" : uri.path
      else
        url
      end

      # Given a URL like https://example.com/download.php?file=foo-1.0.tar.gz
      # the extension we want is ".tar.gz", not ".php".
      Pathname.new(uri_path).ascend do |path|
        ext = path.extname[/[^?&]+/]
        return ext if ext
      end

      nil
    end
    private :parse_extname

    def migrate_cache_entries_to_double_dashes(initial_version)
      return if initial_version && initial_version > "1.7.1"

      return if ENV.key?("HOMEBREW_DISABLE_LOAD_FORMULA")

      return unless HOMEBREW_CACHE.directory?
      return if HOMEBREW_CACHE.children.empty?

      ohai "Migrating cache entries..."

      Formula.each do |formula|
        formula_resources(formula).each do |resource|
          downloader = resource.downloader

          url = downloader.url
          name = resource.download_name
          version = resource.version

          extname = parse_extname(url)
          old_location = downloader.cache/"#{name}-#{version}#{extname}"
          new_location = downloader.cache/"#{name}--#{version}#{extname}"

          next unless old_location.file?

          if new_location.exist?
            begin
              FileUtils.rm_rf old_location
            rescue Errno::EACCES
              opoo "Could not remove #{old_location}, please do so manually."
            end
          else
            begin
              FileUtils.mv old_location, new_location
            rescue Errno::EACCES
              opoo "Could not move #{old_location} to #{new_location}, please do so manually."
            end
          end
        end
      end
    end

    def migrate_cache_entries_to_symlinks(initial_version)
      return if initial_version && initial_version > "1.7.2"

      return if ENV.key?("HOMEBREW_DISABLE_LOAD_FORMULA")

      return unless HOMEBREW_CACHE.directory?
      return if HOMEBREW_CACHE.children.empty?

      ohai "Migrating cache entries..."

      cache_entries = lambda do |path|
        if path.directory?
          path.children
              .reject(&:symlink?)
              .select(&:file?)
              .map { |child| child.basename.to_s }
              .select { |basename| basename.include?("--") }
              .map { |basename| basename.sub(/\-\-.*/, "") }
              .uniq
        else
          []
        end
      end

      load_formula = lambda do |formula|
        begin
          Formula[formula]
        rescue FormulaUnavailableError
          nil
        end
      end

      load_cask = lambda do |cask|
        begin
          Cask::CaskLoader.load(cask)
        rescue Cask::CaskUnavailableError
          nil
        end
      end

      formula_downloaders =
        cache_entries.call(HOMEBREW_CACHE)
                     .map(&load_formula)
                     .compact
                     .flat_map { |formula| formula_resources(formula) }
                     .map { |resource| [resource.downloader, resource.download_name, resource.version] }

      cask_downloaders =
        cache_entries.call(HOMEBREW_CACHE/"Cask")
                     .map(&load_cask)
                     .compact
                     .map { |cask| [Cask::Download.new(cask).downloader, cask.token, cask.version] }

      downloaders = formula_downloaders + cask_downloaders

      downloaders.each do |downloader, name, version|
        next unless downloader.respond_to?(:symlink_location)

        url = downloader.url
        extname = parse_extname(url)
        old_location = downloader.cache/"#{name}--#{version}#{extname}"
        next unless old_location.file?

        new_symlink_location = downloader.symlink_location
        new_location = downloader.cached_location

        if new_location.exist? && new_symlink_location.symlink?
          begin
            FileUtils.rm_rf old_location unless old_location == new_symlink_location
          rescue Errno::EACCES
            opoo "Could not remove #{old_location}, please do so manually."
          end
        else
          begin
            new_location.dirname.mkpath
            if new_location.exist?
              FileUtils.rm_rf old_location
            else
              FileUtils.mv old_location, new_location
            end
            symlink_target = new_location.relative_path_from(new_symlink_location.dirname)
            new_symlink_location.dirname.mkpath
            FileUtils.ln_s symlink_target, new_symlink_location, force: true
          rescue Errno::EACCES
            opoo "Could not move #{old_location} to #{new_location}, please do so manually."
          end
        end
      end
    end

    def migrate_legacy_cache_if_necessary
      legacy_cache = Pathname.new "/Library/Caches/Homebrew"
      return if HOMEBREW_CACHE.to_s == legacy_cache.to_s
      return unless legacy_cache.directory?
      return unless legacy_cache.readable_real?

      migration_attempted_file = legacy_cache/".migration_attempted"
      return if migration_attempted_file.exist?

      return unless legacy_cache.writable_real?

      FileUtils.touch migration_attempted_file

      # This directory could have been compromised if it's world-writable/
      # a symlink/owned by another user so don't copy files in those cases.
      world_writable = legacy_cache.stat.mode & 0777 == 0777
      return if world_writable
      return if legacy_cache.symlink?
      return if !legacy_cache.owned? && legacy_cache.lstat.uid.nonzero?

      ohai "Migrating #{legacy_cache} to #{HOMEBREW_CACHE}..."
      HOMEBREW_CACHE.mkpath
      legacy_cache.cd do
        legacy_cache.entries.each do |f|
          next if [".", "..", ".migration_attempted"].include? f.to_s

          begin
            FileUtils.cp_r f, HOMEBREW_CACHE
          rescue
            @migration_failed ||= true
          end
        end
      end

      if @migration_failed
        opoo <<~EOS
          Failed to migrate #{legacy_cache} to
          #{HOMEBREW_CACHE}. Please do so manually.
        EOS
      else
        ohai "Deleting #{legacy_cache}..."
        FileUtils.rm_rf legacy_cache
        if legacy_cache.exist?
          FileUtils.touch migration_attempted_file
          opoo <<~EOS
            Failed to delete #{legacy_cache}.
            Please do so manually.
          EOS
        end
      end
    end

    def migrate_legacy_keg_symlinks_if_necessary
      legacy_linked_kegs = HOMEBREW_LIBRARY/"LinkedKegs"
      return unless legacy_linked_kegs.directory?

      HOMEBREW_LINKED_KEGS.mkpath unless legacy_linked_kegs.children.empty?
      legacy_linked_kegs.children.each do |link|
        name = link.basename.to_s
        src = begin
          link.realpath
        rescue Errno::ENOENT
          begin
            (HOMEBREW_PREFIX/"opt/#{name}").realpath
          rescue Errno::ENOENT
            begin
              Formulary.factory(name).installed_prefix
            rescue
              next
            end
          end
        end
        dst = HOMEBREW_LINKED_KEGS/name
        dst.unlink if dst.exist?
        FileUtils.ln_sf(src.relative_path_from(dst.parent), dst)
      end
      FileUtils.rm_rf legacy_linked_kegs

      legacy_pinned_kegs = HOMEBREW_LIBRARY/"PinnedKegs"
      return unless legacy_pinned_kegs.directory?

      HOMEBREW_PINNED_KEGS.mkpath unless legacy_pinned_kegs.children.empty?
      legacy_pinned_kegs.children.each do |link|
        name = link.basename.to_s
        src = link.realpath
        dst = HOMEBREW_PINNED_KEGS/name
        FileUtils.ln_sf(src.relative_path_from(dst.parent), dst)
      end
      FileUtils.rm_rf legacy_pinned_kegs
    end

    def migrate_legacy_repository_if_necessary
      return unless Homebrew.default_prefix?
      return unless Homebrew.default_prefix?(HOMEBREW_REPOSITORY)

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

      new_homebrew_repository = Pathname.new "#{HOMEBREW_PREFIX}/Homebrew"
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
      extra_remove_paths = [
        ".git",
        "Library/Locks",
        "Library/Taps",
        "Library/Homebrew/cask",
        "Library/Homebrew/test",
      ]
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

      Keg::MUST_EXIST_DIRECTORIES.each { |dir| FileUtils.mkdir_p dir }

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
      if HOMEBREW_PREFIX == "/usr/local"
        puts <<~EOS
          Homebrew no longer needs to have ownership of #{HOMEBREW_PREFIX}. If you wish you can
          return #{HOMEBREW_PREFIX} to its default ownership with:
            sudo chown root:wheel #{HOMEBREW_PREFIX}
        EOS
      end
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
end
