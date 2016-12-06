#:  * `reinstall` <formula>:
#:    Uninstall and then install <formula>.

require "formula_installer"
require "development_tools"

module Homebrew
  module_function

  def reinstall
    FormulaInstaller.prevent_build_flags unless DevelopmentTools.installed?

    ARGV.resolved_formulae.each do |f|
      if f.pinned?
        onoe "#{f.full_name} is pinned. You must unpin it to reinstall."
        next
      end
      reinstall_formula(f)
    end
  end

  def reinstall_formula(f)
    options = BuildOptions.new(Options.create(ARGV.flags_only), f.options).used_options
    options |= f.build.used_options
    options &= f.options

    notice  = "Reinstalling #{f.full_name}"
    notice += " with #{options * ", "}" unless options.empty?
    oh1 notice

    if f.opt_prefix.directory?
      keg = Keg.new(f.opt_prefix.resolved_path)
      backup keg
    end

    fi = FormulaInstaller.new(f)
    fi.options             = options
    fi.build_bottle        = ARGV.build_bottle? || (!f.bottled? && f.build.build_bottle?)
    fi.build_from_source   = ARGV.build_from_source? || ARGV.build_all_from_source?
    fi.force_bottle        = ARGV.force_bottle?
    fi.interactive         = ARGV.interactive?
    fi.git                 = ARGV.git?
    fi.verbose             = ARGV.verbose?
    fi.debug               = ARGV.debug?
    fi.prelude
    fi.install
    fi.finish
  rescue FormulaInstallationAlreadyAttemptedError
    # next
  rescue Exception
    ignore_interrupts { restore_backup(keg, f) }
    raise
  else
    backup_path(keg).rmtree if backup_path(keg).exist?
  end

  def backup(keg)
    keg.unlink
    keg.rename backup_path(keg)
  end

  def restore_backup(keg, formula)
    path = backup_path(keg)

    return unless path.directory?

    path.rename keg
    keg.link unless formula.keg_only?
  end

  def backup_path(path)
    Pathname.new "#{path}.reinstall"
  end
end
