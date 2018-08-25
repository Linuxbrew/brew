require "hbc/cask_loader"
require "hbc/download"

module UpdateMigrator
  module_function

  def migrate_cache_entries_to_symlinks(initial_version)
    return if initial_version && initial_version > "1.7.2"

    return if ENV.key?("HOMEBREW_DISABLE_LOAD_FORMULA")

    ohai "Migrating cache entries..."

    load_formula = lambda do |formula|
      begin
        Formula[formula]
      rescue FormulaUnavailableError
        nil
      end
    end

    load_cask = lambda do |cask|
      begin
        Hbc::CaskLoader.load(cask)
      rescue Hbc::CaskUnavailableError
        nil
      end
    end

    formula_downloaders = if HOMEBREW_CACHE.directory?
      HOMEBREW_CACHE.children
                    .reject(&:symlink?)
                    .select(&:file?)
                    .map { |child| child.basename.to_s.sub(/\-\-.*/, "") }
                    .uniq
                    .map(&load_formula)
                    .compact
                    .flat_map { |formula| formula_resources(formula) }
                    .map { |resource| [resource.downloader, resource.download_name, resource.version] }
    else
      []
    end

    cask_downloaders = if (HOMEBREW_CACHE/"Cask").directory?
      (HOMEBREW_CACHE/"Cask").children
                             .reject(&:symlink?)
                             .select(&:file?)
                             .map { |child| child.basename.to_s.sub(/\-\-.*/, "") }
                             .uniq
                             .map(&load_cask)
                             .compact
                             .map { |cask| [Hbc::Download.new(cask).downloader, cask.token, cask.version] }
    else
      []
    end

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
end
