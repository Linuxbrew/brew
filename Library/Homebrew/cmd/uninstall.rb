#:  * `uninstall`, `rm`, `remove` [`--force`] [`--ignore-dependencies`] <formula>:
#:    Uninstall <formula>.
#:
#:    If `--force` (or `-f`) is passed, and there are multiple versions of <formula>
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
          begin
            f = Formulary.from_rack(rack)
            if f.pinned?
              onoe "#{f.full_name} is pinned. You must unpin it to uninstall."
              next
            end
          rescue
            nil
          end

          keg.lock do
            puts "Uninstalling #{keg}... (#{keg.abv})"
            keg.unlink
            keg.uninstall
            rack = keg.rack
            rm_pin rack

            if rack.directory?
              versions = rack.subdirs.map(&:basename)
              puts "#{keg.name} #{versions.to_sentence} #{"is".pluralize(versions.count)} still installed."
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
  rescue MethodDeprecatedError
    # Silently ignore deprecations when uninstalling.
    nil
  end

  def check_for_dependents(kegs)
    return false unless result = Keg.find_some_installed_dependents(kegs)

    if ARGV.homebrew_developer?
      DeveloperDependentsMessage.new(*result).output
    else
      NondeveloperDependentsMessage.new(*result).output
    end

    true
  end

  class DependentsMessage
    attr_reader :reqs, :deps

    def initialize(requireds, dependents)
      @reqs = requireds
      @deps = dependents
    end

    protected

    def sample_command
      "brew uninstall --ignore-dependencies #{ARGV.named.join(" ")}"
    end

    def are_required_by_deps
      "#{"is".pluralize(reqs.count)} required by #{deps.to_sentence}, " \
      "which #{"is".pluralize(deps.count)} currently installed"
    end
  end

  class DeveloperDependentsMessage < DependentsMessage
    def output
      opoo <<~EOS
        #{reqs.to_sentence} #{are_required_by_deps}.
        You can silence this warning with:
          #{sample_command}
      EOS
    end
  end

  class NondeveloperDependentsMessage < DependentsMessage
    def output
      ofail <<~EOS
        Refusing to uninstall #{reqs.to_sentence}
        because #{"it".pluralize(reqs.count)} #{are_required_by_deps}.
        You can override this and force removal with:
          #{sample_command}
      EOS
    end
  end

  def rm_pin(rack)
    Formulary.from_rack(rack).unpin
  rescue
    nil
  end
end
