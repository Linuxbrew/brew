#:  * `uninstall`, `rm`, `remove` [`--force`] <formula>:
#:    Uninstall <formula>.
#:
#:    If `--force` is passed, and there are multiple versions of <formula>
#:    installed, delete all installed versions.

require "keg"
require "formula"
require "diagnostic"
require "migrator"

module Homebrew
  module_function

  def uninstall
    raise KegUnspecifiedError if ARGV.named.empty?

    kegs_by_rack = if ARGV.force?
      Hash[ARGV.named.map { |name|
        rack = Formulary.to_rack(name)
        [rack, rack.subdirs.map { |d| Keg.new(d) }]
      }]
    else
      ARGV.kegs.group_by(&:rack)
    end

    # --ignore-dependencies, to be consistent with install
    if !ARGV.include?("--ignore-dependencies") && !ARGV.homebrew_developer?
      all_kegs = kegs_by_rack.values.flatten(1)
      return if check_for_dependents all_kegs
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

  def check_for_dependents(kegs)
    return false unless result = Keg.find_some_installed_dependents(kegs)

    requireds, dependents = result

    msg = "Refusing to uninstall #{requireds.join(", ")} because "
    msg << (requireds.count == 1 ? "it is" : "they are")
    msg << " required by #{dependents.join(", ")}, which "
    msg << (dependents.count == 1 ? "is" : "are")
    msg << " currently installed."
    ofail msg
    print "You can override this and force removal with "
    puts "`brew uninstall --ignore-dependencies #{requireds.map(&:name).join(" ")}`."

    true
  end

  # Will return some kegs, and some dependencies, if they're present.
  # For efficiency, we don't bother trying to get complete data.
  def find_some_installed_dependents(kegs)
    kegs.each do |keg|
      dependents = keg.installed_dependents - kegs
      dependents.map! { |d| "#{d.name} #{d.version}" }
      return [keg], dependents if dependents.any?
    end

    # Find formulae that didn't have dependencies saved in all of their kegs,
    # so need them to be calculated now.
    #
    # This happens after the initial dependency check because it's sloooow.
    remaining_formulae = Formula.installed.select { |f|
      f.installed_kegs.any? { |k| Tab.for_keg(k).runtime_dependencies.nil? }
    }

    keg_names = kegs.map(&:name)
    kegs_by_name = kegs.group_by(&:to_formula)
    remaining_formulae.each do |dependent|
      required = dependent.missing_dependencies(hide: keg_names)
      required.select! do |f|
        kegs_by_name.key?(f)
      end
      next unless required.any?

      required_kegs = required.map { |f| kegs_by_name[f].sort_by(&:version).last }
      return required_kegs, [dependent]
    end

    nil
  end

  def rm_pin(rack)
    Formulary.from_rack(rack).unpin
  rescue
    nil
  end
end
