#:  * `leaves`:
#:    Show installed formulae that are not dependencies of another installed formula.

require "formula"
require "tab"
require "set"

module Homebrew
  module_function

  def leaves
    installed = Formula.installed.sort

    deps_of_installed = installed.flat_map do |f|
      f.runtime_dependencies.map(&:to_formula).map(&:full_name)
    end

    leaves = installed.map(&:full_name) - deps_of_installed
    leaves.each(&method(:puts))
  end
end
