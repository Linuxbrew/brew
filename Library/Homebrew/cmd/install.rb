#:  * `install` [`--debug`] [`--env=`(`std`|`super`)] [`--ignore-dependencies`|`--only-dependencies`] [`--cc=`<compiler>] [`--build-from-source`|`--force-bottle`] [`--devel`|`--HEAD`] [`--keep-tmp`] [`--build-bottle`] <formula> [<options> ...]:
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
#:    `gcc-4.2` for Apple's GCC 4.2, or `gcc-4.9` for a Homebrew-provided GCC
#:    4.9.
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

require "missing_formula"
require "diagnostic"
require "cmd/search"
require "formula_installer"
require "tap"
require "hardware"
require "development_tools"

module Homebrew
  module_function

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
          raise <<-EOS.undent
          #{f.full_name} is a head-only formula
          Install with `brew install --HEAD #{f.full_name}`
          EOS
        end

        # devel-only without --devel is an error
        if !ARGV.build_devel? && f.stable.nil? && f.head.nil?
          raise <<-EOS.undent
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
            onoe <<-EOS.undent
              #{f.full_name} #{optlinked_version} is already installed
              To upgrade to #{f.version}, run `brew upgrade #{f.name}`
            EOS
          else
            opoo <<-EOS.undent
              #{f.full_name} #{f.pkg_version} is already installed
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
            msg = <<-EOS.undent
              #{msg}
              The currently linked version is #{f.linked_version}
              You can use `brew switch #{f} #{installed_version}` to link this version.
            EOS
          elsif !f.linked? || f.keg_only?
            msg = <<-EOS.undent
              #{msg}, it's just not linked.
              You can use `brew link #{f}` to link this version.
            EOS
          end
          opoo msg
        elsif !f.any_version_installed? && old_formula = f.old_installed_formulae.first
          msg = "#{old_formula.full_name} #{old_formula.installed_version} already installed"
          if !old_formula.linked? && !old_formula.keg_only?
            msg = <<-EOS.undent
              #{msg}, it's just not linked.
              You can use `brew link #{old_formula.full_name}` to link this version.
            EOS
          end
          opoo msg
        elsif f.migration_needed? && !ARGV.force?
          # Check if the formula we try to install is the same as installed
          # but not migrated one. If --force passed then install anyway.
          opoo <<-EOS.undent
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

      perform_preinstall_checks

      formulae.each do |f|
        Migrator.migrate_if_needed(f)
        install_formula(f)
      end
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
      if (reason = Homebrew::MissingFormula.reason(e.name))
        $stderr.puts reason
        return
      end

      query = query_regexp(e.name)

      ohai "Searching for similarly named formulae..."
      formulae_search_results = search_formulae(query)
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
      taps_search_results = search_taps(query)
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

  def check_ppc
    case Hardware::CPU.type
    when :ppc
      abort <<-EOS.undent
        Sorry, Homebrew does not support your computer's CPU architecture.
        For PPC support, see: https://github.com/mistydemeo/tigerbrew
      EOS
    end
  end

  def check_writable_install_location
    raise "Cannot write to #{HOMEBREW_CELLAR}" if HOMEBREW_CELLAR.exist? && !HOMEBREW_CELLAR.writable_real?
    raise "Cannot write to #{HOMEBREW_PREFIX}" unless HOMEBREW_PREFIX.writable_real? || HOMEBREW_PREFIX.to_s == "/usr/local"
  end

  def check_development_tools
    checks = Diagnostic::Checks.new
    checks.fatal_development_tools_checks.each do |check|
      out = checks.send(check)
      next if out.nil?
      ofail out
    end
    exit 1 if Homebrew.failed?
  end

  def check_cellar
    FileUtils.mkdir_p HOMEBREW_CELLAR unless File.exist? HOMEBREW_CELLAR
  rescue
    raise <<-EOS.undent
      Could not create #{HOMEBREW_CELLAR}
      Check you have permission to write to #{HOMEBREW_CELLAR.parent}
    EOS
  end

  def perform_preinstall_checks
    check_ppc
    check_writable_install_location
    check_development_tools if DevelopmentTools.installed?
    check_cellar
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
  rescue CannotInstallFormulaError => e
    ofail e.message
  end
end
