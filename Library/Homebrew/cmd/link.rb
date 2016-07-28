#:  * `ln`, `link` [`--overwrite`] [`--dry-run`] [`--force`] <formula>:
#:    Symlink all of <formula>'s installed files into the Homebrew prefix. This
#:    is done automatically when you install formulae but can be useful for DIY
#:    installations.
#:
#:    If `--overwrite` is passed, Homebrew will delete files which already exist in
#:    the prefix while linking.
#:
#:    If `--dry-run` or `-n` is passed, Homebrew will list all files which would
#:    be linked or which would be deleted by `brew link --overwrite`, but will not
#:    actually link or delete any files.
#:
#:    If `--force` is passed, Homebrew will allow keg-only formulae to be linked.

require "ostruct"

module Homebrew
  def link
    raise KegUnspecifiedError if ARGV.named.empty?

    mode = OpenStruct.new

    mode.overwrite = true if ARGV.include? "--overwrite"
    mode.dry_run = true if ARGV.dry_run?

    ARGV.kegs.each do |keg|
      if HOMEBREW_PREFIX.to_s == "/usr/local" && keg.name == "openssl"
        opoo <<-EOS.undent
          Refusing to link: openssl
          Linking keg-only OpenSSL means you may end up linking against the insecure,
          deprecated system version while using the headers from the Homebrew version.
          Instead, pass the full include/library paths to your compiler e.g.:
            -I#{HOMEBREW_PREFIX}/opt/openssl/include -L#{HOMEBREW_PREFIX}/opt/openssl/lib
        EOS
        next
      elsif keg.linked?
        opoo "Already linked: #{keg}"
        puts "To relink: brew unlink #{keg.name} && brew link #{keg.name}"
        next
      elsif keg_only?(keg.rack) && !ARGV.force?
        opoo "#{keg.name} is keg-only and must be linked with --force"
        puts "Note that doing so can interfere with building software."
        next
      elsif mode.dry_run && mode.overwrite
        puts "Would remove:"
        keg.link(mode)

        next
      elsif mode.dry_run
        puts "Would link:"
        keg.link(mode)

        next
      end

      keg.lock do
        print "Linking #{keg}... "
        puts if ARGV.verbose?

        begin
          n = keg.link(mode)
        rescue Keg::LinkError
          puts
          raise
        else
          puts "#{n} symlinks created"
        end
      end
    end
  end

  private

  def keg_only?(rack)
    Formulary.from_rack(rack).keg_only?
  rescue FormulaUnavailableError, TapFormulaAmbiguityError, TapFormulaWithOldnameAmbiguityError
    false
  end
end
