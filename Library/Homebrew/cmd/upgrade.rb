#:  * `upgrade` [<install-options>] [`--cleanup`] [`--fetch-HEAD`] [<formulae>]:
#:    Upgrade outdated, unpinned brews.
#:
#:    Options for the `install` command are also valid here.
#:
#:    If `--cleanup` is specified then remove previously installed <formula> version(s).
#:
#:    If `--fetch-HEAD` is passed, fetch the upstream repository to detect if
#:    the HEAD installation of the formula is outdated. Otherwise, the
#:    repository's HEAD will be checked for updates when a new stable or devel
#:    version has been released.
#:
#:    If <formulae> are given, upgrade only the specified brews (but do so even
#:    if they are pinned; see `pin`, `unpin`).

require "cmd/install"
require "cleanup"
require "development_tools"

module Homebrew
  module_function

  def upgrade
    FormulaInstaller.prevent_build_flags unless DevelopmentTools.installed?

    Homebrew.perform_preinstall_checks

    if ARGV.include?("--all")
      opoo <<-EOS.undent
        We decided to not change the behaviour of `brew upgrade` so
        `brew upgrade --all` is equivalent to `brew upgrade` without any other
        arguments (so the `--all` is a no-op and can be removed).
      EOS
    end

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

    unless upgrade_pinned?
      pinned = outdated.select(&:pinned?)
      outdated -= pinned
    end

    formulae_to_install = outdated.map(&:latest_formula)

    if formulae_to_install.empty?
      oh1 "No packages to upgrade"
    else
      oh1 "Upgrading #{Formatter.pluralize(formulae_to_install.length, "outdated package")}, with result:"
      puts formulae_to_install.map { |f| "#{f.full_specified_name} #{f.pkg_version}" } * ", "
    end

    unless upgrade_pinned? || pinned.empty?
      oh1 "Not upgrading #{Formatter.pluralize(pinned.length, "pinned package")}:"
      puts pinned.map { |f| "#{f.full_specified_name} #{f.pkg_version}" } * ", "
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
      upgrade_formula(f)
      next unless ARGV.include?("--cleanup")
      next unless f.installed?
      Homebrew::Cleanup.cleanup_formula f
    end
  end

  def upgrade_pinned?
    !ARGV.named.empty?
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

    fi = FormulaInstaller.new(f)
    fi.options  = f.build.used_options
    fi.options &= f.options
    fi.build_bottle = ARGV.build_bottle? || (!f.bottled? && f.build.build_bottle?)
    fi.installed_on_request = !ARGV.named.empty?
    fi.link_keg             = keg_was_linked if keg_had_linked_opt
    if tab
      fi.installed_as_dependency = tab.installed_as_dependency
      fi.installed_on_request  ||= tab.installed_on_request
    end
    fi.prelude

    oh1 "Upgrading #{f.full_specified_name} #{fi.options.to_a.join " "}"

    # first we unlink the currently active keg for this formula otherwise it is
    # possible for the existing build to interfere with the build we are about to
    # do! Seriously, it happens!
    outdated_kegs.each(&:unlink)

    fi.install
    fi.finish

    # If the formula was pinned, and we were force-upgrading it, unpin and
    # pin it again to get a symlink pointing to the correct keg.
    if f.pinned?
      f.unpin
      f.pin
    end
  rescue FormulaInstallationAlreadyAttemptedError
    # We already attempted to upgrade f as part of the dependency tree of
    # another formula. In that case, don't generate an error, just move on.
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
