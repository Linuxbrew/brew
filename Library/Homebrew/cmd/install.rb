#:  * `install` [`--debug`] [`--env=`(`std`|`super`)] [`--ignore-dependencies`|`--only-dependencies`] [`--cc=`<compiler>] [`--build-from-source`|`--force-bottle`] [`--include-test`] [`--devel`|`--HEAD`] [`--keep-tmp`] [`--build-bottle`] [`--force`] [`--verbose`] [`--display-times`] <formula> [<options> ...]:
#:    Install <formula>.
#:
#:    <formula> is usually the name of the formula to install, but it can be specified
#:    in several different ways. See [SPECIFYING FORMULAE](#specifying-formulae).
#:
#:    If `--debug` (or `-d`) is passed and brewing fails, open an interactive debugging
#:    session with access to IRB or a shell inside the temporary build directory.
#:
#:    If `--env=std` is passed, use the standard build environment instead of superenv.
#:
#:    If `--env=super` is passed, use superenv even if the formula specifies the
#:    standard build environment.
#:
#:    If `--ignore-dependencies` is passed, skip installing any dependencies of
#:    any kind. If they are not already present, the formula will probably fail
#:    to install.
#:
#:    If `--only-dependencies` is passed, install the dependencies with specified
#:    options but do not install the specified formula.
#:
#:    If `--cc=`<compiler> is passed, attempt to compile using <compiler>.
#:    <compiler> should be the name of the compiler's executable, for instance
#:    `gcc-8` for gcc 8, `gcc-4.2` for Apple's GCC 4.2, or `gcc-4.9` for a
#:    Homebrew-provided GCC 4.9. In order to use LLVM's clang, use
#:    `llvm_clang`. To specify the Apple-provided clang, use `clang`. This
#:    parameter will only accept compilers that are provided by Homebrew or
#:    bundled with macOS. Please do not file issues if you encounter errors
#:    while using this flag.
#:
#:    If `--build-from-source` (or `-s`) is passed, compile the specified <formula> from
#:    source even if a bottle is provided. Dependencies will still be installed
#:    from bottles if they are available.
#:
#:    If `HOMEBREW_BUILD_FROM_SOURCE` is set, regardless of whether `--build-from-source` was
#:    passed, then both <formula> and the dependencies installed as part of this process
#:    are built from source even if bottles are available.
#:
#:    If `--force-bottle` is passed, install from a bottle if it exists for the
#:    current or newest version of macOS, even if it would not normally be used
#:    for installation.
#:
#:    If `--include-test` is passed, install testing dependencies. These are only
#:    needed by formulae maintainers to run `brew test`.
#:
#:    If `--devel` is passed, and <formula> defines it, install the development version.
#:
#:    If `--HEAD` is passed, and <formula> defines it, install the HEAD version,
#:    aka master, trunk, unstable.
#:
#:    If `--keep-tmp` is passed, the temporary files created during installation
#:    are not deleted.
#:
#:    If `--build-bottle` is passed, prepare the formula for eventual bottling
#:    during installation.
#:
#:    If `--force` (or `-f`) is passed, install without checking for previously
#:    installed keg-only or non-migrated versions
#:
#:    If `--verbose` (or `-v`) is passed, print the verification and postinstall steps.
#:
#:    If `--display-times` is passed, install times for each formula are printed
#:    at the end of the run.
#:
#:    Installation options specific to <formula> may be appended to the command,
#:    and can be listed with `brew options` <formula>.
#:
#:  * `install` `--interactive` [`--git`] <formula>:
#:    If `--interactive` (or `-i`) is passed, download and patch <formula>, then
#:    open a shell. This allows the user to run `./configure --help` and
#:    otherwise determine how to turn the software package into a Homebrew
#:    formula.
#:
#:    If `--git` (or `-g`) is passed, Homebrew will create a Git repository, useful for
#:    creating patches to the software.
#:
#:    If `HOMEBREW_INSTALL_CLEANUP` is set then remove previously installed versions
#:    of upgraded <formulae> as well as the HOMEBREW_CACHE for that formula.

require "missing_formula"
require "formula_installer"
require "development_tools"
require "install"
require "search"

module Homebrew
  module_function

  extend Search

  def install
    raise FormulaUnspecifiedError if ARGV.named.empty?

    if ARGV.include? "--head"
      raise "Specify `--HEAD` in uppercase to build from trunk."
    end

    unless ARGV.force?
      ARGV.named.each do |name|
        next if File.exist?(name)
        if name !~ HOMEBREW_TAP_FORMULA_REGEX && name !~ HOMEBREW_CASK_TAP_CASK_REGEX
          next
        end

        tap = Tap.fetch(Regexp.last_match(1), Regexp.last_match(2))
        tap.install unless tap.installed?
      end
    end

    begin
      formulae = []

      unless ARGV.casks.empty?
        args = []
        args << "--force" if ARGV.force?
        args << "--debug" if ARGV.debug?
        args << "--verbose" if ARGV.verbose?

        ARGV.casks.each do |c|
          ohai "brew cask install #{c} #{args.join " "}"
          system("#{HOMEBREW_PREFIX}/bin/brew", "cask", "install", c, *args)
        end
      end

      # if the user's flags will prevent bottle only-installations when no
      # developer tools are available, we need to stop them early on
      FormulaInstaller.prevent_build_flags unless DevelopmentTools.installed?

      ARGV.formulae.each do |f|
        # head-only without --HEAD is an error
        if !ARGV.build_head? && f.stable.nil? && f.devel.nil?
          raise <<~EOS
            #{f.full_name} is a head-only formula
            Install with `brew install --HEAD #{f.full_name}`
          EOS
        end

        # devel-only without --devel is an error
        if !ARGV.build_devel? && f.stable.nil? && f.head.nil?
          raise <<~EOS
            #{f.full_name} is a devel-only formula
            Install with `brew install --devel #{f.full_name}`
          EOS
        end

        if ARGV.build_stable? && f.stable.nil?
          raise "#{f.full_name} has no stable download, please choose --devel or --HEAD"
        end

        # --HEAD, fail with no head defined
        if ARGV.build_head? && f.head.nil?
          raise "No head is defined for #{f.full_name}"
        end

        # --devel, fail with no devel defined
        if ARGV.build_devel? && f.devel.nil?
          raise "No devel block is defined for #{f.full_name}"
        end

        installed_head_version = f.latest_head_version
        new_head_installed = installed_head_version &&
                             !f.head_version_outdated?(installed_head_version, fetch_head: ARGV.fetch_head?)
        prefix_installed = f.prefix.exist? && !f.prefix.children.empty?

        if f.keg_only? && f.any_version_installed? && f.optlinked? && !ARGV.force?
          # keg-only install is only possible when no other version is
          # linked to opt, because installing without any warnings can break
          # dependencies. Therefore before performing other checks we need to be
          # sure --force flag is passed.
          if f.outdated?
            optlinked_version = Keg.for(f.opt_prefix).version
            onoe <<~EOS
              #{f.full_name} #{optlinked_version} is already installed
              To upgrade to #{f.version}, run `brew upgrade #{f.name}`
            EOS
          elsif ARGV.only_deps?
            formulae << f
          else
            opoo <<~EOS
              #{f.full_name} #{f.pkg_version} is already installed and up-to-date
              To reinstall #{f.pkg_version}, run `brew reinstall #{f.name}`
            EOS
          end
        elsif (ARGV.build_head? && new_head_installed) || prefix_installed
          # After we're sure that --force flag is passed for linked to opt
          # keg-only we need to be sure that the version we're attempting to
          # install is not already installed.

          installed_version = if ARGV.build_head?
            f.latest_head_version
          else
            f.pkg_version
          end

          msg = "#{f.full_name} #{installed_version} is already installed"
          linked_not_equals_installed = f.linked_version != installed_version
          if f.linked? && linked_not_equals_installed
            msg = <<~EOS
              #{msg}
              The currently linked version is #{f.linked_version}
              You can use `brew switch #{f} #{installed_version}` to link this version.
            EOS
          elsif !f.linked? || f.keg_only?
            msg = <<~EOS
              #{msg}, it's just not linked
              You can use `brew link #{f}` to link this version.
            EOS
          elsif ARGV.only_deps?
            msg = nil
            formulae << f
          else
            msg = <<~EOS
              #{msg} and up-to-date
              To reinstall #{f.pkg_version}, run `brew reinstall #{f.name}`
            EOS
          end
          opoo msg if msg
        elsif !f.any_version_installed? && old_formula = f.old_installed_formulae.first
          msg = "#{old_formula.full_name} #{old_formula.installed_version} already installed"
          if !old_formula.linked? && !old_formula.keg_only?
            msg = <<~EOS
              #{msg}, it's just not linked.
              You can use `brew link #{old_formula.full_name}` to link this version.
            EOS
          end
          opoo msg
        elsif f.migration_needed? && !ARGV.force?
          # Check if the formula we try to install is the same as installed
          # but not migrated one. If --force passed then install anyway.
          opoo <<~EOS
            #{f.oldname} already installed, it's just not migrated
            You can migrate formula with `brew migrate #{f}`
            Or you can force install it with `brew install #{f} --force`
          EOS
        else
          # If none of the above is true and the formula is linked, then
          # FormulaInstaller will handle this case.
          formulae << f
        end

        # Even if we don't install this formula mark it as no longer just
        # installed as a dependency.
        next unless f.opt_prefix.directory?

        keg = Keg.new(f.opt_prefix.resolved_path)
        tab = Tab.for_keg(keg)
        unless tab.installed_on_request
          tab.installed_on_request = true
          tab.write
        end
      end

      return if formulae.empty?

      Install.perform_preinstall_checks

      formulae.each do |f|
        Migrator.migrate_if_needed(f)
        install_formula(f)
        Cleanup.new.cleanup_formula(f) if ENV["HOMEBREW_INSTALL_CLEANUP"]
      end
      Homebrew.messages.display_messages
    rescue FormulaUnreadableError, FormulaClassUnavailableError,
           TapFormulaUnreadableError, TapFormulaClassUnavailableError => e
      # Need to rescue before `FormulaUnavailableError` (superclass of this)
      # is handled, as searching for a formula doesn't make sense here (the
      # formula was found, but there's a problem with its implementation).
      ofail e.message
    rescue FormulaUnavailableError => e
      if e.name == "updog"
        ofail "What's updog?"
        return
      end

      ofail e.message
      if (reason = MissingFormula.reason(e.name))
        $stderr.puts reason
        return
      end

      ohai "Searching for similarly named formulae..."
      formulae_search_results = search_formulae(e.name)
      case formulae_search_results.length
      when 0
        ofail "No similarly named formulae found."
      when 1
        puts "This similarly named formula was found:"
        puts formulae_search_results
        puts "To install it, run:\n  brew install #{formulae_search_results.first}"
      else
        puts "These similarly named formulae were found:"
        puts Formatter.columns(formulae_search_results)
        puts "To install one of them, run (for example):\n  brew install #{formulae_search_results.first}"
      end

      # Do not search taps if the formula name is qualified
      return if e.name.include?("/")

      ohai "Searching taps..."
      taps_search_results = search_taps(e.name)[:formulae]
      case taps_search_results.length
      when 0
        ofail "No formulae found in taps."
      when 1
        puts "This formula was found in a tap:"
        puts taps_search_results
        puts "To install it, run:\n  brew install #{taps_search_results.first}"
      else
        puts "These formulae were found in taps:"
        puts Formatter.columns(taps_search_results)
        puts "To install one of them, run (for example):\n  brew install #{taps_search_results.first}"
      end
    end
  end

  def install_formula(f)
    f.print_tap_action
    build_options = f.build

    fi = FormulaInstaller.new(f)
    fi.options              = build_options.used_options
    fi.invalid_option_names = build_options.invalid_option_names
    fi.ignore_deps          = ARGV.ignore_deps?
    fi.only_deps            = ARGV.only_deps?
    fi.build_bottle         = ARGV.build_bottle?
    fi.interactive          = ARGV.interactive?
    fi.git                  = ARGV.git?
    fi.prelude
    fi.install
    fi.finish
  rescue FormulaInstallationAlreadyAttemptedError
    # We already attempted to install f as part of the dependency tree of
    # another formula. In that case, don't generate an error, just move on.
    nil
  rescue CannotInstallFormulaError => e
    ofail e.message
  end
end
