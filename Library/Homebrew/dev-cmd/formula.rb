#:  * `formula` <formulae>:
#:    Display the path where a formula is located.

require "formula"
require "cli_parser"

module Homebrew
  module_function

  def formula_args
    Homebrew::CLI::Parser.new do
      usage_banner <<~EOS
        `formula` <formulae>

        Display the path where a formula is located.
      EOS
      switch :verbose
      switch :debug
    end
  end

  def formula
    formula_args.parse

    raise FormulaUnspecifiedError if ARGV.named.empty?

    ARGV.resolved_formulae.each { |f| puts f.path }
  end
end
