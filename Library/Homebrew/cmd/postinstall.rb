#:  * `postinstall` <formula>:
#:    Rerun the post-install steps for <formula>.

require "sandbox"
require "formula_installer"
require "cli_parser"

module Homebrew
  module_function

  def postinstall_args
    Homebrew::CLI::Parser.new do
      usage_banner <<~EOS
        `postinstall` <formula>

        Rerun the post-install steps for <formula>.
      EOS
      switch :verbose
      switch :force
      switch :debug
    end
  end

  def postinstall
    postinstall_args.parse

    ARGV.resolved_formulae.each do |f|
      ohai "Postinstalling #{f}"
      fi = FormulaInstaller.new(f)
      fi.post_install
    end
  end
end
