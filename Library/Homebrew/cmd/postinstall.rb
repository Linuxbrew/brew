#:  * `postinstall` <formula>:
#:    Rerun the post-install steps for <formula>.

require "sandbox"
require "formula_installer"

module Homebrew
  module_function

  def postinstall
    ARGV.resolved_formulae.each do |f|
      ohai "Postinstalling #{f}"
      fi = FormulaInstaller.new(f)
      fi.post_install
    end
  end
end
