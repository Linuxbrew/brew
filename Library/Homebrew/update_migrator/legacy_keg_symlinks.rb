module UpdateMigrator
  module_function

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
end
