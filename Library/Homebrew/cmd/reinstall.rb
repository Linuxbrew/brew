#:  * `reinstall` [`--display-times`] <formula>:
#:    Uninstall and then install <formula> (with existing install options).
#:
#:    If `--display-times` is passed, install times for each formula are printed
#:    at the end of the run.

require "formula_installer"
require "development_tools"
require "messages"
require "reinstall"

module Homebrew
  module_function

  def reinstall
    FormulaInstaller.prevent_build_flags unless DevelopmentTools.installed?

    Install.perform_preinstall_checks

    ARGV.resolved_formulae.each do |f|
      if f.pinned?
        onoe "#{f.full_name} is pinned. You must unpin it to reinstall."
        next
      end
      Migrator.migrate_if_needed(f)
      reinstall_formula(f)
    end
    Homebrew.messages.display_messages
  end
end
