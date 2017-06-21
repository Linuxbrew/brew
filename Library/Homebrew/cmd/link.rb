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
#:    If `--force` (or `-f`) is passed, Homebrew will allow keg-only formulae to be linked.

require "ostruct"

module Homebrew
  module_function

  def link
    raise KegUnspecifiedError if ARGV.named.empty?

    mode = OpenStruct.new

    mode.overwrite = true if ARGV.include? "--overwrite"
    mode.dry_run = true if ARGV.dry_run?

    ARGV.kegs.each do |keg|
      keg_only = keg_only?(keg.rack)
      if HOMEBREW_PREFIX.to_s == "/usr/local" && keg_only &&
         keg.name.start_with?("openssl", "libressl")
        opoo <<-EOS.undent
          Refusing to link: #{keg.name}
          Linking keg-only #{keg.name} means you may end up linking against the insecure,
          deprecated system OpenSSL while using the headers from Homebrew's #{keg.name}.
          Instead, pass the full include/library paths to your compiler e.g.:
            -I#{HOMEBREW_PREFIX}/opt/#{keg.name}/include -L#{HOMEBREW_PREFIX}/opt/#{keg.name}/lib
        EOS
        next
      elsif keg.linked?
        opoo "Already linked: #{keg}"
        puts "To relink: brew unlink #{keg.name} && brew link #{keg.name}"
        next
      elsif keg_only && !ARGV.force?
        opoo "#{keg.name} is keg-only and must be linked with --force"
        puts "Note that doing so can interfere with building software."
        puts_keg_only_path_message(keg)
        next
      elsif mode.dry_run && mode.overwrite
        puts "Would remove:"
        keg.link(mode)

        next
      elsif mode.dry_run
        puts "Would link:"
        keg.link(mode)
        puts_keg_only_path_message(keg) if keg_only

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

        puts_keg_only_path_message(keg) if keg_only && !ARGV.homebrew_developer?
      end
    end
  end

  def puts_keg_only_path_message(keg)
    bin = keg/"bin"
    sbin = keg/"sbin"
    return if !bin.directory? && !sbin.directory?

    opt = HOMEBREW_PREFIX/"opt/#{keg.name}"
    puts "\nIf you need to have this software first in your PATH instead consider running:"
    puts "  #{Utils::Shell.prepend_path_in_profile(opt/"bin")}"  if bin.directory?
    puts "  #{Utils::Shell.prepend_path_in_profile(opt/"sbin")}" if sbin.directory?
  end

  def keg_only?(rack)
    Formulary.from_rack(rack).keg_only?
  rescue FormulaUnavailableError, TapFormulaAmbiguityError, TapFormulaWithOldnameAmbiguityError
    false
  end
end
