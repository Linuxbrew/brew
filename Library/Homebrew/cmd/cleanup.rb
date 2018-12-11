#:  * `cleanup` [`--prune=`<days>] [`--dry-run`] [`-s`] [<formulae>|<casks>]:
#:    Remove stale lock files and outdated downloads for formulae and casks,
#:    and remove old versions of installed formulae. If arguments are specified,
#:    only do this for the specified formulae and casks.
#:
#:    If `--prune=`<days> is specified, remove all cache files older than <days>.
#:
#:    If `--dry-run` or `-n` is passed, show what would be removed, but do not
#:    actually remove anything.
#:
#:    If `-s` is passed, scrub the cache, including downloads for even the latest
#:    versions. Note downloads for any installed formula or cask will still not
#:    be deleted. If you want to delete those too: `rm -rf "$(brew --cache)"`

require "cleanup"
require "cli_parser"

module Homebrew
  module_function

  def cleanup_args
    Homebrew::CLI::Parser.new do
      usage_banner <<~EOS
        `cleanup` [<options>] [<formulae>|<casks>]


        Remove stale lock files and outdated downloads for formulae and casks,
        and remove old versions of installed formulae. If arguments are specified,
        only do this for the specified formulae and casks.
      EOS

      flag   "--prune=",
        description: "Remove all cache files older than specified <days>."
      switch "-n", "--dry-run",
        description: "Show what would be removed, but do not actually remove anything."
      switch "-s",
        description: "Scrub the cache, including downloads for even the latest versions. "\
                     "Note downloads for any installed formula or cask will still not be deleted. "\
                     "If you want to delete those too: `rm -rf \"$(brew --cache)\"`"
      switch :verbose
      switch :debug
    end
  end

  def cleanup
    cleanup_args.parse

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
