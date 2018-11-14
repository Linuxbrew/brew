#:  * `unlink` [`--dry-run`] <formula>:
#:    Remove symlinks for <formula> from the Homebrew prefix. This can be useful
#:    for temporarily disabling a formula:
#:    `brew unlink` <formula> `&&` <commands> `&& brew link` <formula>
#:
#:    If `--dry-run` or `-n` is passed, Homebrew will list all files which would
#:    be unlinked, but will not actually unlink or delete any files.

require "ostruct"
require "cli_parser"

module Homebrew
  module_function

  def unlink_args
    Homebrew::CLI::Parser.new do
      usage_banner <<~EOS
        `unlink` [<options>] <formula>

        Remove symlinks for <formula> from the Homebrew prefix. This can be useful
        for temporarily disabling a formula:
        `brew unlink` <formula> `&&` <commands> `&& brew link` <formula>
      EOS
      switch "-n", "--dry-run",
        description: "List all files which would be unlinked, but will  not actually unlink or "\
                     "delete any files."
      switch :verbose
      switch :debug
    end
  end

  def unlink
    unlink_args.parse

    raise KegUnspecifiedError if args.remaining.empty?

    mode = OpenStruct.new
    mode.dry_run = true if args.dry_run?

    ARGV.kegs.each do |keg|
      if mode.dry_run
        puts "Would remove:"
        keg.unlink(mode)
        next
      end

      keg.lock do
        print "Unlinking #{keg}... "
        puts if args.verbose?
        puts "#{keg.unlink(mode)} symlinks removed"
      end
    end
  end
end
