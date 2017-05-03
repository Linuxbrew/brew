#:  * `cleanup` [`--prune=`<days>] [`--dry-run`] [`-s`] [<formulae>]:
#:    For all installed or specific formulae, remove any older versions from the
#:    cellar. In addition, old downloads from the Homebrew download-cache are deleted.
#:
#:    If `--prune=`<days> is specified, remove all cache files older than <days>.
#:
#:    If `--dry-run` or `-n` is passed, show what would be removed, but do not
#:    actually remove anything.
#:
#:    If `-s` is passed, scrub the cache, removing downloads for even the latest
#:    versions of formulae. Note downloads for any installed formulae will still not be
#:    deleted. If you want to delete those too: `rm -rf $(brew --cache)`

require "cleanup"
require "utils"

module Homebrew
  module_function

  def cleanup
    if ARGV.named.empty?
      Cleanup.cleanup
    else
      Cleanup.cleanup_cellar(ARGV.resolved_formulae)
    end

    report_disk_usage unless Cleanup.disk_cleanup_size.zero?
    report_unremovable_kegs unless Cleanup.unremovable_kegs.empty?
  end

  def report_disk_usage
    disk_space = disk_usage_readable(Cleanup.disk_cleanup_size)
    if ARGV.dry_run?
      ohai "This operation would free approximately #{disk_space} of disk space."
    else
      ohai "This operation has freed approximately #{disk_space} of disk space."
    end
  end

  def report_unremovable_kegs
    ofail <<-EOS.undent
      Could not cleanup old kegs! Fix your permissions on:
        #{Cleanup.unremovable_kegs.join "\n  "}
    EOS
  end
end
