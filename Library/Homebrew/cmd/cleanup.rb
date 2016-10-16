#:  * `cleanup` [`--prune=`<days>] [`--dry-run`] [`-s`] [<formulae>]:
#:    For all installed or specific formulae, remove any older versions from the
#:    cellar. In addition, old downloads from the Homebrew download-cache are deleted.
#:
#:    If `--prune=`<days> is specified, remove all cache files older than <days>.
#:
#:    If `--dry-run` or `-n` is passed, show what would be removed, but do not
#:    actually remove anything.
#:
#:    If `-s` is passed, scrubs the cache, removing downloads for even the latest
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
      ARGV.resolved_formulae.each { |f| Cleanup.cleanup_formula f }
    end

    return if Cleanup.disk_cleanup_size.zero?

    disk_space = disk_usage_readable(Cleanup.disk_cleanup_size)
    if ARGV.dry_run?
      ohai "This operation would free approximately #{disk_space} of disk space."
    else
      ohai "This operation has freed approximately #{disk_space} of disk space."
    end
  end
end
