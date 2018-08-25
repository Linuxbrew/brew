module UpdateMigrator
  module_function

  def migrate_cache_entries_to_double_dashes(initial_version)
    return if initial_version && initial_version > "1.7.1"

    return if ENV.key?("HOMEBREW_DISABLE_LOAD_FORMULA")

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
end
