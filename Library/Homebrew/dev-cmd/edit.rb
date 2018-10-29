#:  * `edit`:
#:    Open the Homebrew repository for editing.
#:
#:  * `edit` <formula>:
#:    Open <formula> in the editor set by `EDITOR` or `HOMEBREW_EDITOR`.

require "formula"
require "cli_parser"

module Homebrew
  module_function

  def edit_args
    Homebrew::CLI::Parser.new do
      usage_banner <<~EOS
        `edit` [<formulae>]

        Open a formula in the editor set by `EDITOR` or `HOMEBREW_EDITOR`, or open the
        Homebrew repository for editing if no <formula> is provided.
      EOS
      switch :force
      switch :verbose
      switch :debug
    end
  end

  def edit
    edit_args.parse

    unless (HOMEBREW_REPOSITORY/".git").directory?
      raise <<~EOS
        Changes will be lost!
        The first time you `brew update', all local changes will be lost; you should
        thus `brew update' before you `brew edit'!
      EOS
    end

    # If no brews are listed, open the project root in an editor.
    paths = [HOMEBREW_REPOSITORY] if ARGV.named.empty?

    # Don't use ARGV.formulae as that will throw if the file doesn't parse
    paths ||= ARGV.named.map do |name|
      path = Formulary.path(name)
      raise FormulaUnavailableError, name if !path.file? && !args.force?

      path
    end

    exec_editor(*paths)
  end
end
