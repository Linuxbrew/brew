#:  * `uninstall`, `rm`, `remove` [`--force`] [`--ignore-dependencies`] <formula>:
#:    Uninstall <formula>.
#:
#:    If `--force` is passed, and there are multiple versions of <formula>
#:    installed, delete all installed versions.
#:
#:    If `--ignore-dependencies` is passed, uninstalling won't fail, even if
#:    formulae depending on <formula> would still be installed.

require "keg"
require "formula"
require "diagnostic"
require "migrator"

module Homebrew
  module_function

  def uninstall
    raise KegUnspecifiedError if ARGV.named.empty?

    kegs_by_rack = if ARGV.force?
      Hash[ARGV.named.map do |name|
        rack = Formulary.to_rack(name)
        next unless rack.directory?
        [rack, rack.subdirs.map { |d| Keg.new(d) }]
      end]
    else
      ARGV.kegs.group_by(&:rack)
    end

    handle_unsatisfied_dependents(kegs_by_rack)
    return if Homebrew.failed?

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

  def handle_unsatisfied_dependents(kegs_by_rack)
    return if ARGV.include?("--ignore-dependencies")

    all_kegs = kegs_by_rack.values.flatten(1)
    check_for_dependents all_kegs
  end

  def check_for_dependents(kegs)
    return false unless result = Keg.find_some_installed_dependents(kegs)

    if ARGV.homebrew_developer?
      dependents_output_for_developers(*result)
    else
      dependents_output_for_nondevelopers(*result)
    end

    true
  end

  def dependents_output_for_developers(requireds, dependents)
    msg = requireds.join(", ")
    msg << (requireds.count == 1 ? " is" : " are")
    msg << " required by #{dependents.join(", ")}, which "
    msg << (dependents.count == 1 ? "is" : "are")
    msg << " currently installed."
    msg << "\nYou can silence this warning with "
    msg << "`brew uninstall --ignore-dependencies "
    msg << "#{requireds.map(&:name).join(" ")}`."
    opoo msg
  end

  def dependents_output_for_nondevelopers(requireds, dependents)
    msg = "Refusing to uninstall #{requireds.join(", ")} because "
    msg << (requireds.count == 1 ? "it is" : "they are")
    msg << " required by #{dependents.join(", ")}, which "
    msg << (dependents.count == 1 ? "is" : "are")
    msg << " currently installed."
    msg << "\nYou can override this and force removal with "
    msg << "`brew uninstall --ignore-dependencies "
    msg << "#{requireds.map(&:name).join(" ")}`."
    ofail msg
  end

  def rm_pin(rack)
    Formulary.from_rack(rack).unpin
  rescue
    nil
  end
end
