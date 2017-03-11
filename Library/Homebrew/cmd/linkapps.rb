#:  * `linkapps` [`--local`] [<formulae>]:
#:    Find installed formulae that provide `.app`-style macOS apps and symlink them
#:    into `/Applications`, allowing for easier access (deprecated).
#:
#:    Unfortunately `brew linkapps` cannot behave nicely with e.g. Spotlight using
#:    either aliases or symlinks and Homebrew formulae do not build "proper" `.app`
#:    bundles that can be relocated. Instead, please consider using `brew cask` and
#:    migrate formulae using `.app`s to casks.
#:
#:    If no <formulae> are provided, all of them will have their apps symlinked.
#:
#:    If provided, `--local` will symlink them into the user's `~/Applications`
#:    directory instead of the system directory.

require "keg"
require "formula"

module Homebrew
  module_function

  def linkapps
    opoo <<-EOS.undent
      `brew linkapps` has been deprecated and will eventually be removed!

      Unfortunately `brew linkapps` cannot behave nicely with e.g. Spotlight using
      either aliases or symlinks and Homebrew formulae do not build "proper" `.app`
      bundles that can be relocated. Instead, please consider using `brew cask` and
      migrate formulae using `.app`s to casks.
    EOS

    target_dir = linkapps_target(local: ARGV.include?("--local"))

    unless target_dir.directory?
      opoo "#{target_dir} does not exist, stopping."
      puts "Run `mkdir #{target_dir}` first."
      exit 1
    end

    if ARGV.named.empty?
      kegs = Formula.racks.map do |rack|
        keg = rack.subdirs.map { |d| Keg.new(d) }
        next if keg.empty?
        keg.detect(&:linked?) || keg.max_by(&:version)
      end
    else
      kegs = ARGV.kegs
    end

    link_count = 0
    kegs.each do |keg|
      keg.apps.each do |app|
        puts "Linking: #{app}"
        target_app = target_dir/app.basename

        if target_app.exist? && !target_app.symlink?
          onoe "#{target_app} already exists, skipping."
          next
        end

        # We prefer system `ln` over `FileUtils.ln_sf` because the latter seems
        # to have weird failure conditions (that were observed in the past).
        system "ln", "-sf", app, target_dir
        link_count += 1
      end
    end

    if link_count.zero?
      puts "No apps linked to #{target_dir}" if ARGV.verbose?
    else
      puts "Linked #{Formatter.pluralize(link_count, "app")} to #{target_dir}"
    end
  end

  def linkapps_target(opts = {})
    local = opts.fetch(:local, false)
    Pathname.new(local ? "~/Applications" : "/Applications").expand_path
  end
end
