#:  * `edit`:
#:    Open all of Homebrew for editing.
#:
#:  * `edit` <formula>:
#:    Open <formula> in the editor.

require "formula"
require "cli_parser"

module Homebrew
  module_function

  def edit
    args = Homebrew::CLI::Parser.parse do
      switch "--force"
    end

    unless (HOMEBREW_REPOSITORY/".git").directory?
      raise <<~EOS
        Changes will be lost!
        The first time you `brew update', all local changes will be lost, you should
        thus `brew update' before you `brew edit'!
        EOS
    end

    # If no brews are listed, open the project root in an editor.
    if ARGV.named.empty?
      editor = File.basename which_editor
      if ["atom", "subl", "mate"].include?(editor)
        # If the user is using Atom, Sublime Text or TextMate
        # give a nice project view instead.
        exec_editor HOMEBREW_REPOSITORY/"bin/brew",
                    HOMEBREW_REPOSITORY/"README.md",
                    HOMEBREW_REPOSITORY/".gitignore",
                    *library_folders
      else
        exec_editor HOMEBREW_REPOSITORY
      end
    else
      # Don't use ARGV.formulae as that will throw if the file doesn't parse
      paths = ARGV.named.map do |name|
        path = Formulary.path(name)

        raise FormulaUnavailableError, name unless path.file? || args.force?

        path
      end
      exec_editor(*paths)
    end
  end

  def library_folders
    Dir["#{HOMEBREW_LIBRARY}/*"].reject do |d|
      case File.basename(d)
      when "LinkedKegs", "Aliases" then true
      end
    end
  end
end
