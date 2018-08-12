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
require "cli_parser"

module Homebrew
  module_function

  def cleanup
    CLI::Parser.parse do
      switch "-n", "--dry-run"
      switch "-s"
      flag   "--prune="
    end

    cleanup = Cleanup.new(*args.remaining, dry_run: args.dry_run?, scrub: args.s?, days: args.prune&.to_i)

    cleanup.clean!

    unless cleanup.disk_cleanup_size.zero?
      disk_space = disk_usage_readable(cleanup.disk_cleanup_size)
      if args.dry_run?
        ohai "This operation would free approximately #{disk_space} of disk space."
      else
        ohai "This operation has freed approximately #{disk_space} of disk space."
      end
    end

    return if cleanup.unremovable_kegs.empty?

    ofail <<~EOS
      Could not cleanup old kegs! Fix your permissions on:
        #{cleanup.unremovable_kegs.join "\n  "}
    EOS
  end
end
