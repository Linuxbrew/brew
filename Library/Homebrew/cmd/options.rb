#:  * `options` [`--compact`] (`--all`|`--installed`|<formulae>):
#:    Display install options specific to <formulae>.
#:
#:    If `--compact` is passed, show all options on a single line separated by
#:    spaces.
#:
#:    If `--all` is passed, show options for all formulae.
#:
#:    If `--installed` is passed, show options for all installed formulae.

require "formula"
require "options"

module Homebrew
  module_function

  def options
    if ARGV.include? "--all"
      puts_options Formula.to_a.sort
    elsif ARGV.include? "--installed"
      puts_options Formula.installed.sort
    else
      raise FormulaUnspecifiedError if ARGV.named.empty?

      puts_options ARGV.formulae
    end
  end

  def puts_options(formulae)
    formulae.each do |f|
      next if f.options.empty?

      if ARGV.include? "--compact"
        puts f.options.as_flags.sort * " "
      else
        puts f.full_name if formulae.length > 1
        dump_options_for_formula f
        puts
      end
    end
  end
end
