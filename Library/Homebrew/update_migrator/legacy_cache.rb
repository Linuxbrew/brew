module UpdateMigrator
  module_function

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
end
