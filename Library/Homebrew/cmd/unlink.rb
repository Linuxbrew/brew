#:  * `unlink` [`--dry-run`] <formula>:
#:    Remove symlinks for <formula> from the Homebrew prefix. This can be useful
#:    for temporarily disabling a formula:
#:    `brew unlink <formula> && <commands> && brew link <formula>`
#:
#:    If `--dry-run` or `-n` is passed, Homebrew will list all files which would
#:    be unlinked, but will not actually unlink or delete any files.

require "ostruct"

module Homebrew
  module_function

  def unlink
    raise KegUnspecifiedError if ARGV.named.empty?

    mode = OpenStruct.new
    mode.dry_run = true if ARGV.dry_run?

    ARGV.kegs.each do |keg|
      if mode.dry_run
        puts "Would remove:"
        keg.unlink(mode)
        next
      end

      keg.lock do
        print "Unlinking #{keg}... "
        puts if ARGV.verbose?
        puts "#{keg.unlink(mode)} symlinks removed"
      end
    end
  end
end
