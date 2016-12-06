module Hbc
  module Cache
    module_function

    def ensure_cache_exists
      return if Hbc.cache.exist?

      odebug "Creating Cache at #{Hbc.cache}"
      Hbc.cache.mkpath
    end

    def migrate_legacy_cache
      return unless Hbc.legacy_cache.exist?

      ohai "Migrating cached files to #{Hbc.cache}..."
      Hbc.legacy_cache.children.select(&:symlink?).each do |symlink|
        file = symlink.readlink

        new_name = file.basename
                       .sub(/\-((?:(\d|#{DSL::Version::DIVIDER_REGEX})*\-\2*)*[^\-]+)$/x,
                            '--\1')

        renamed_file = Hbc.cache.join(new_name)

        if file.exist?
          puts "#{file} -> #{renamed_file}"
          FileUtils.mv(file, renamed_file)
        end

        FileUtils.rm(symlink)
      end

      FileUtils.remove_entry_secure(Hbc.legacy_cache)
    end
  end
end
