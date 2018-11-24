#:  * `leaves`:
#:    Show installed formulae that are not dependencies of another installed formula.

require "formula"
require "tab"
require "cli_parser"

module Homebrew
  module_function

  def leaves_args
    Homebrew::CLI::Parser.new do
      usage_banner <<~EOS
        `leaves`

        Show installed formulae that are not dependencies of another installed formula.
      EOS
      switch :debug
    end
  end

  def leaves
    leaves_args.parse

    installed = Formula.installed.sort

    deps_of_installed = installed.flat_map do |f|
      f.runtime_dependencies.map do |dep|
        begin
          dep.to_formula.full_name
        rescue FormulaUnavailableError
          dep.name
        end
      end
    end

    leaves = installed.map(&:full_name) - deps_of_installed
    leaves.each(&method(:puts))
  end
end
