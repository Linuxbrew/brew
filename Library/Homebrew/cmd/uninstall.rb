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
      Hash[ARGV.named.map do |name|
        rack = Formulary.to_rack(name)
        [rack, rack.subdirs.map { |d| Keg.new(d) }]
      end]
    else
      ARGV.kegs.group_by(&:rack)
    end

    if should_check_for_dependents?
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

  def should_check_for_dependents?
    # --ignore-dependencies, to be consistent with install
    return false if ARGV.include?("--ignore-dependencies")
    return false if ARGV.homebrew_developer?
    true
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

  def rm_pin(rack)
    Formulary.from_rack(rack).unpin
  rescue
    nil
  end
end
