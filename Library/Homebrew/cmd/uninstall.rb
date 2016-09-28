#:  * `uninstall`, `rm`, `remove` [`--force`] <formula>:
#:    Uninstall <formula>.
#:
#:    If `--force` is passed, and there are multiple versions of <formula>
#:    installed, delete all installed versions.

require "keg"
require "formula"
require "migrator"

module Homebrew
  module_function

  def uninstall
    raise KegUnspecifiedError if ARGV.named.empty?

    kegs_by_rack = if ARGV.force?
      Hash[ARGV.named.map do |name|
        rack = Formulary.to_rack(name)
        [rack, rack.subdirs.map { |d| Keg.new(d) }]
      end]
    else
      ARGV.kegs.group_by(&:rack)
    end

    kegs = kegs_by_rack.values.flatten(1)

    kegs.each do |keg|
      dependents = keg.installed_dependents - kegs
      if dependents.any?
        dependents_output = dependents.map { |k| "#{k.name} #{k.version}" }.join(", ")
        conjugation = dependents.count == 1 ? "is" : "are"
        ofail "Refusing to uninstall #{keg} because it is required by #{dependents_output}, which #{conjugation} currently installed."
        # puts "You can override this and force removal with `brew uninstall --force #{keg.name}`."
        next
      end
    end

    kegs_by_rack.each do |rack, kegs|
      if ARGV.force?
        name = rack.basename

        if rack.directory?
          puts "Uninstalling #{name}... (#{rack.abv})"
          kegs.each do |keg|
            keg.unlink
            keg.uninstall
          end
        end

        rm_pin rack
      else
        kegs.each do |keg|
          keg.lock do
            puts "Uninstalling #{keg}... (#{keg.abv})"
            keg.unlink
            keg.uninstall
            rack = keg.rack
            rm_pin rack

            if rack.directory?
              versions = rack.subdirs.map(&:basename)
              verb = versions.length == 1 ? "is" : "are"
              puts "#{keg.name} #{versions.join(", ")} #{verb} still installed."
              puts "Remove all versions with `brew uninstall --force #{keg.name}`."
            end
          end
        end
      end
    end
  rescue MultipleVersionsInstalledError => e
    ofail e
    puts "Use `brew uninstall --force #{e.name}` to remove all versions."
  ensure
    # If we delete Cellar/newname, then Cellar/oldname symlink
    # can become broken and we have to remove it.
    if HOMEBREW_CELLAR.directory?
      HOMEBREW_CELLAR.children.each do |rack|
        rack.unlink if rack.symlink? && !rack.resolved_path_exists?
      end
    end
  end

  def rm_pin(rack)
    Formulary.from_rack(rack).unpin
  rescue
    nil
  end
end
