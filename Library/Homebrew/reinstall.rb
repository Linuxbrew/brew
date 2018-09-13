require "formula_installer"
require "development_tools"
require "messages"

module Homebrew
  module_function

  def reinstall_formula(f, build_from_source: false)
    if f.opt_prefix.directory?
      keg = Keg.new(f.opt_prefix.resolved_path)
      keg_had_linked_opt = true
      keg_was_linked = keg.linked?
      backup keg
    end

    build_options = BuildOptions.new(Options.create(ARGV.flags_only), f.options)
    options = build_options.used_options
    options |= f.build.used_options
    options &= f.options

    fi = FormulaInstaller.new(f)
    fi.options              = options
    fi.invalid_option_names = build_options.invalid_option_names
    fi.build_bottle         = ARGV.build_bottle? || (!f.bottled? && f.build.bottle?)
    fi.interactive          = ARGV.interactive?
    fi.git                  = ARGV.git?
    fi.link_keg           ||= keg_was_linked if keg_had_linked_opt
    fi.build_from_source    = true if build_from_source
    fi.prelude

    oh1 "Reinstalling #{Formatter.identifier(f.full_name)} #{options.to_a.join " "}"

    fi.install
    fi.finish
  rescue FormulaInstallationAlreadyAttemptedError
    nil
  rescue Exception # rubocop:disable Lint/RescueException
    ignore_interrupts { restore_backup(keg, keg_was_linked) }
    raise
  else
    backup_path(keg).rmtree if backup_path(keg).exist?
  end

  def backup(keg)
    keg.unlink
    keg.rename backup_path(keg)
  end

  def restore_backup(keg, keg_was_linked)
    path = backup_path(keg)

    return unless path.directory?

    Pathname.new(keg).rmtree if keg.exist?

    path.rename keg
    keg.link if keg_was_linked
  end

  def backup_path(path)
    Pathname.new "#{path}.reinstall"
  end
end
