#:  * `leaves`:
#:    Show installed formulae that are not dependencies of another installed formula.

require "formula"
require "tab"
require "set"

module Homebrew
  module_function

  def leaves
    installed = Formula.installed.sort
    deps_of_installed = Set.new

    installed.each do |f|
      deps = f.runtime_dependencies.map { |d| d.to_formula.full_name }
      deps_of_installed.merge(deps)
    end

    installed.each do |f|
      puts f.full_name unless deps_of_installed.include? f.full_name
    end
  end
end
