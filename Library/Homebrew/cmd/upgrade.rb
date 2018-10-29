#:  * `upgrade` [<install-options>] [`--cleanup`] [`--fetch-HEAD`] [`--ignore-pinned`] [`--display-times`] [<formulae>]:
#:    Upgrade outdated, unpinned brews (with existing install options).
#:
#:    Options for the `install` command are also valid here.
#:
#:    If `--cleanup` is specified or `HOMEBREW_INSTALL_CLEANUP` is set then remove
#:    previously installed version(s) of upgraded <formulae>.
#:
#:    If `--fetch-HEAD` is passed, fetch the upstream repository to detect if
#:    the HEAD installation of the formula is outdated. Otherwise, the
#:    repository's HEAD will be checked for updates when a new stable or devel
#:    version has been released.
#:
#:    If `--ignore-pinned` is passed, set a 0 exit code even if pinned formulae
#:    are not upgraded.
#:
#:    If `--display-times` is passed, install times for each formula are printed
#:    at the end of the run.
#:
#:    If <formulae> are given, upgrade only the specified brews (unless they
#:    are pinned; see `pin`, `unpin`).

require "install"
require "reinstall"
require "formula_installer"
require "cleanup"
require "development_tools"
require "messages"

module Homebrew
  module_function

  def upgrade
    FormulaInstaller.prevent_build_flags unless DevelopmentTools.installed?

    Install.perform_preinstall_checks

    if ARGV.named.empty?
      outdated = Formula.installed.select do |f|
        f.outdated?(fetch_head: ARGV.fetch_head?)
      end

      exit 0 if outdated.empty?
    else
      outdated = ARGV.resolved_formulae.select do |f|
        f.outdated?(fetch_head: ARGV.fetch_head?)
      end

      (ARGV.resolved_formulae - outdated).each do |f|
        versions = f.installed_kegs.map(&:version)
        if versions.empty?
          onoe "#{f.full_specified_name} not installed"
        else
          version = versions.max
          onoe "#{f.full_specified_name} #{version} already installed"
        end
      end
      exit 1 if outdated.empty?
    end

    pinned = outdated.select(&:pinned?)
    outdated -= pinned
    formulae_to_install = outdated.map(&:latest_formula)

    if !pinned.empty? && !ARGV.include?("--ignore-pinned")
      ofail "Not upgrading #{pinned.count} pinned #{"package".pluralize(pinned.count)}:"
      puts pinned.map { |f| "#{f.full_specified_name} #{f.pkg_version}" } * ", "
    end

    if formulae_to_install.empty?
      oh1 "No packages to upgrade"
    else
      oh1 "Upgrading #{formulae_to_install.count} outdated #{"package".pluralize(formulae_to_install.count)}:"
      formulae_upgrades = formulae_to_install.map do |f|
        if f.optlinked?
          "#{f.full_specified_name} #{Keg.new(f.opt_prefix).version} -> #{f.pkg_version}"
        else
          "#{f.full_specified_name} #{f.pkg_version}"
        end
      end
      puts formulae_upgrades.join(", ")
    end

    upgrade_formulae(formulae_to_install)

    check_dependents(formulae_to_install)

    Homebrew.messages.display_messages
  end

  def upgrade_formulae(formulae_to_install)
    return if formulae_to_install.empty?

    # Sort keg-only before non-keg-only formulae to avoid any needless conflicts
    # with outdated, non-keg-only versions of formulae being upgraded.
    formulae_to_install.sort! do |a, b|
      if !a.keg_only? && b.keg_only?
        1
      elsif a.keg_only? && !b.keg_only?
        -1
      else
        0
      end
    end

    formulae_to_install.each do |f|
      Migrator.migrate_if_needed(f)
      begin
        upgrade_formula(f)
        next if !ARGV.include?("--cleanup") && !ENV["HOMEBREW_UPGRADE_CLEANUP"] && !ENV["HOMEBREW_INSTALL_CLEANUP"]
        next unless f.installed?

        Cleanup.new.cleanup_formula(f)
      rescue UnsatisfiedRequirements => e
        Homebrew.failed = true
        onoe "#{f}: #{e}"
      end
    end
  end

  def upgrade_formula(f)
    if f.opt_prefix.directory?
      keg = Keg.new(f.opt_prefix.resolved_path)
      keg_had_linked_opt = true
      keg_was_linked = keg.linked?
    end

    formulae_maybe_with_kegs = [f] + f.old_installed_formulae
    outdated_kegs = formulae_maybe_with_kegs
                    .map(&:linked_keg)
                    .select(&:directory?)
                    .map { |k| Keg.new(k.resolved_path) }
    linked_kegs = outdated_kegs.select(&:linked?)

    if f.opt_prefix.directory?
      keg = Keg.new(f.opt_prefix.resolved_path)
      tab = Tab.for_keg(keg)
    end

    build_options = BuildOptions.new(Options.create(ARGV.flags_only), f.options)
    options = build_options.used_options
    options |= f.build.used_options
    options &= f.options

    fi = FormulaInstaller.new(f)
    fi.options = options
    fi.build_bottle = ARGV.build_bottle? || (!f.bottled? && f.build.bottle?)
    fi.installed_on_request = !ARGV.named.empty?
    fi.link_keg           ||= keg_was_linked if keg_had_linked_opt
    if tab
      fi.installed_as_dependency = tab.installed_as_dependency
      fi.installed_on_request  ||= tab.installed_on_request
    end
    fi.prelude

    oh1 "Upgrading #{Formatter.identifier(f.full_specified_name)} #{fi.options.to_a.join " "}"

    # first we unlink the currently active keg for this formula otherwise it is
    # possible for the existing build to interfere with the build we are about to
    # do! Seriously, it happens!
    outdated_kegs.each(&:unlink)

    fi.install
    fi.finish
  rescue FormulaInstallationAlreadyAttemptedError
    # We already attempted to upgrade f as part of the dependency tree of
    # another formula. In that case, don't generate an error, just move on.
    nil
  rescue CannotInstallFormulaError => e
    ofail e
  rescue BuildError => e
    e.dump
    puts
    Homebrew.failed = true
  rescue DownloadError => e
    ofail e
  ensure
    # restore previous installation state if build failed
    begin
      linked_kegs.each(&:link) unless f.installed?
    rescue
      nil
    end
  end

  def upgradable_dependents(kegs, formulae)
    formulae_to_upgrade = Set.new
    formulae_pinned = Set.new

    formulae.each do |formula|
      descendants = Set.new

      dependents = kegs.select do |keg|
        keg.runtime_dependencies
           .any? { |d| d["full_name"] == formula.full_name }
      end

      next if dependents.empty?

      dependent_formulae = dependents.map(&:to_formula)

      dependent_formulae.each do |f|
        next if formulae_to_upgrade.include?(f)
        next if formulae_pinned.include?(f)

        if f.outdated?(fetch_head: ARGV.fetch_head?)
          if f.pinned?
            formulae_pinned << f
          else
            formulae_to_upgrade << f
          end
        end

        descendants << f
      end

      upgradable_descendants, pinned_descendants = upgradable_dependents(kegs, descendants)

      formulae_to_upgrade.merge upgradable_descendants
      formulae_pinned.merge pinned_descendants
    end

    [formulae_to_upgrade, formulae_pinned]
  end

  def broken_dependents(kegs, formulae)
    formulae_to_reinstall = Set.new
    formulae_pinned_and_outdated = Set.new

    CacheStoreDatabase.use(:linkage) do |db|
      formulae.each do |formula|
        descendants = Set.new

        dependents = kegs.select do |keg|
          keg.runtime_dependencies
             .any? { |d| d["full_name"] == formula.full_name }
        end

        next if dependents.empty?

        dependents.each do |keg|
          f = keg.to_formula

          next if formulae_to_reinstall.include?(f)
          next if formulae_pinned_and_outdated.include?(f)

          checker = LinkageChecker.new(keg, cache_db: db)

          if checker.broken_library_linkage?
            if f.outdated?(fetch_head: ARGV.fetch_head?)
              # Outdated formulae = pinned formulae (see function above)
              formulae_pinned_and_outdated << f
            else
              formulae_to_reinstall << f
            end
          end

          descendants << f
        end

        descendants_to_reinstall, descendants_pinned = broken_dependents(kegs, descendants)

        formulae_to_reinstall.merge descendants_to_reinstall
        formulae_pinned_and_outdated.merge descendants_pinned
      end
    end

    [formulae_to_reinstall, formulae_pinned_and_outdated]
  end

  # @private
  def depends_on(a, b)
    if a.opt_or_installed_prefix_keg
        .runtime_dependencies
        .any? { |d| d["full_name"] == b.full_name }
      1
    else
      a <=> b
    end
  end

  # @private
  def formulae_with_runtime_dependencies
    Formula.installed
           .map(&:opt_or_installed_prefix_keg)
           .reject(&:nil?)
           .reject { |f| f.runtime_dependencies.to_a.empty? }
  end

  def check_dependents(formulae)
    return if formulae.empty?

    # First find all the outdated dependents.
    kegs = formulae_with_runtime_dependencies

    return if kegs.empty?

    oh1 "Checking dependents for outdated formulae" if ARGV.verbose?
    upgradable, pinned = upgradable_dependents(kegs, formulae).map(&:to_a)

    upgradable.sort! { |a, b| depends_on(a, b) }

    pinned.sort! { |a, b| depends_on(a, b) }

    # Print the pinned dependents.
    unless pinned.empty?
      ohai "Not upgrading #{pinned.count} pinned #{"dependent".pluralize(pinned.count)}:"
      puts pinned.map { |f| "#{f.full_specified_name} #{f.pkg_version}" } * ", "
    end

    # Print the upgradable dependents.
    if upgradable.empty?
      ohai "No dependents to upgrade" if ARGV.verbose?
    else
      ohai "Upgrading #{upgradable.count} #{"dependent".pluralize(upgradable.count)}:"
      formulae_upgrades = upgradable.map do |f|
        if f.optlinked?
          "#{f.full_specified_name} #{Keg.new(f.opt_prefix).version} -> #{f.pkg_version}"
        else
          "#{f.full_specified_name} #{f.pkg_version}"
        end
      end
      puts formulae_upgrades.join(", ")
    end

    upgrade_formulae(upgradable)

    # Assess the dependents tree again.
    kegs = formulae_with_runtime_dependencies

    oh1 "Checking dependents for broken library links" if ARGV.verbose?
    reinstallable, pinned = broken_dependents(kegs, formulae).map(&:to_a)

    reinstallable.sort! { |a, b| depends_on(a, b) }

    pinned.sort! { |a, b| depends_on(a, b) }

    # Print the pinned dependents.
    unless pinned.empty?
      onoe "Not reinstalling #{pinned.count} broken and outdated, but pinned #{"dependent".pluralize(pinned.count)}:"
      $stderr.puts pinned.map { |f| "#{f.full_specified_name} #{f.pkg_version}" } * ", "
    end

    # Print the broken dependents.
    if reinstallable.empty?
      ohai "No broken dependents to reinstall" if ARGV.verbose?
    else
      ohai "Reinstalling #{reinstallable.count} broken #{"dependent".pluralize(reinstallable.count)} from source:"
      puts reinstallable.map(&:full_specified_name).join(", ")
    end

    reinstallable.each do |f|
      begin
        reinstall_formula(f, build_from_source: true)
      rescue FormulaInstallationAlreadyAttemptedError
        # We already attempted to reinstall f as part of the dependency tree of
        # another formula. In that case, don't generate an error, just move on.
        nil
      rescue CannotInstallFormulaError => e
        ofail e
      rescue BuildError => e
        e.dump
        puts
        Homebrew.failed = true
      rescue DownloadError => e
        ofail e
      end
    end
  end
end
