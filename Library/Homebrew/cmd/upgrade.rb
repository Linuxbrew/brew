#:  * `upgrade` [<install-options>] [`--cleanup`] [`--fetch-HEAD`] [`--ignore-pinned`] [`--display-times`] [<formulae>]:
#:    Upgrade outdated, unpinned brews (with existing install options).
#:
#:    Options for the `install` command are also valid here.
#:
#:    If `--cleanup` is specified or `HOMEBREW_UPGRADE_CLEANUP` is set then remove
#:    previously installed <formula> version(s).
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
require "formula_installer"
require "cleanup"
require "development_tools"
require "messages"

module Homebrew
  module_function

  def upgrade
    FormulaInstaller.prevent_build_flags unless DevelopmentTools.installed?

    Install.perform_preinstall_checks

    odisabled "'brew upgrade --all'", "'brew upgrade'" if ARGV.include?("--all")

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
      ofail "Not upgrading #{Formatter.pluralize(pinned.length, "pinned package")}:"
      puts pinned.map { |f| "#{f.full_specified_name} #{f.pkg_version}" } * ", "
    end

    if formulae_to_install.empty?
      oh1 "No packages to upgrade"
    else
      oh1 "Upgrading #{Formatter.pluralize(formulae_to_install.length, "outdated package")}, with result:"
      formulae_upgrades = formulae_to_install.map do |f|
        if f.optlinked?
          "#{f.full_specified_name} #{Keg.new(f.opt_prefix).version} -> #{f.pkg_version}"
        else
          "#{f.full_specified_name} #{f.pkg_version}"
        end
      end
      puts formulae_upgrades.join(", ")
    end

    # Sort keg_only before non-keg_only formulae to avoid any needless conflicts
    # with outdated, non-keg_only versions of formulae being upgraded.
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
        next if !ARGV.include?("--cleanup") && !ENV["HOMEBREW_UPGRADE_CLEANUP"]
        next unless f.installed?
        Homebrew::Cleanup.cleanup_formula f
      rescue UnsatisfiedRequirements => e
        Homebrew.failed = true
        onoe "#{f}: #{e}"
      end
    end
    Homebrew.messages.display_messages
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
end
