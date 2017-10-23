#:  * `prune` [`--dry-run`]:
#:    Remove dead symlinks from the Homebrew prefix. This is generally not
#:    needed, but can be useful when doing DIY installations. Also remove broken
#:    app symlinks from `/Applications` and `~/Applications` that were previously
#:    created by `brew linkapps`.
#:
#:    If `--dry-run` or `-n` is passed, show what would be removed, but do not
#:    actually remove anything.

require "keg"
require "cmd/tap"
require "cmd/unlinkapps"

module Homebrew
  module_function

  def prune
    ObserverPathnameExtension.reset_counts!

    dirs = []

    Keg::PRUNEABLE_DIRECTORIES.each do |dir|
      next unless dir.directory?
      dir.find do |path|
        path.extend(ObserverPathnameExtension)
        if path.symlink?
          unless path.resolved_path_exists?
            if path.to_s =~ Keg::INFOFILE_RX
              path.uninstall_info unless ARGV.dry_run?
            end

            if ARGV.dry_run?
              puts "Would remove (broken link): #{path}"
            else
              path.unlink
            end
          end
        elsif path.directory? && !Keg::PRUNEABLE_DIRECTORIES.include?(path)
          dirs << path
        end
      end
    end

    dirs.reverse_each do |d|
      if ARGV.dry_run? && d.children.empty?
        puts "Would remove (empty directory): #{d}"
      else
        d.rmdir_if_possible
      end
    end

    unless ARGV.dry_run?
      if ObserverPathnameExtension.total.zero?
        puts "Nothing pruned" if ARGV.verbose?
      else
        n, d = ObserverPathnameExtension.counts
        print "Pruned #{n} symbolic links "
        print "and #{d} directories " if d.positive?
        puts "from #{HOMEBREW_PREFIX}"
      end
    end

    unlinkapps_prune(dry_run: ARGV.dry_run?, quiet: true)
  end
end
