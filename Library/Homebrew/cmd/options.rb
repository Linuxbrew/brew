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
require "cli_parser"

module Homebrew
  module_function

  def options_args
    Homebrew::CLI::Parser.new do
      usage_banner <<~EOS
        `options` [<options>] <formulae>

        Display install options specific to <formulae>
      EOS
      switch "--compact",
        description: "Show all options on a single line separated by spaces."
      switch "--all",
        description: "Show options for all formulae."
      switch "--installed",
        description: "Show options for all installed formulae."
      switch :debug
    end
  end

  def options
    options_args.parse

    if args.all?
      puts_options Formula.to_a.sort
    elsif args.installed?
      puts_options Formula.installed.sort
    else
      raise FormulaUnspecifiedError if args.remaining.empty?

      puts_options ARGV.formulae
    end
  end

  def puts_options(formulae)
    formulae.each do |f|
      next if f.options.empty?

      if args.compact?
        puts f.options.as_flags.sort * " "
      else
        puts f.full_name if formulae.length > 1
        dump_options_for_formula f
        puts
      end
    end
  end
end
