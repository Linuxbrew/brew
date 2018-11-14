#:  * `reinstall` [`--display-times`] <formula>:
#:    Uninstall and then install <formula> (with existing install options).
#:
#:    If `--display-times` is passed, install times for each formula are printed
#:    at the end of the run.
#:
#:    If `HOMEBREW_INSTALL_CLEANUP` is set then remove previously installed versions
#:    of upgraded <formulae> as well as the HOMEBREW_CACHE for that formula.

require "formula_installer"
require "development_tools"
require "messages"
require "reinstall"
require "cli_parser"

module Homebrew
  module_function

  def reinstall_args
    Homebrew::CLI::Parser.new do
      usage_banner <<~EOS
        `reinstall` [<option(s)>] <formula>:

        Uninstall and then install <formula> (with existing install options).

        If `HOMEBREW_INSTALL_CLEANUP` is set then remove previously installed versions
        of upgraded <formulae> as well as the HOMEBREW_CACHE for that formula.
      EOS
      switch "--display-times",
        description: "Print install times for each formula at the end of the run."
      switch :verbose
      switch :debug
    end
  end

  def reinstall
    reinstall_args.parse

    FormulaInstaller.prevent_build_flags unless DevelopmentTools.installed?

    Install.perform_preinstall_checks

    ARGV.resolved_formulae.each do |f|
      if f.pinned?
        onoe "#{f.full_name} is pinned. You must unpin it to reinstall."
        next
      end
      Migrator.migrate_if_needed(f)
      reinstall_formula(f)
      Cleanup.new.cleanup_formula(f) if ENV["HOMEBREW_INSTALL_CLEANUP"]
    end
    Homebrew.messages.display_messages
  end
end
