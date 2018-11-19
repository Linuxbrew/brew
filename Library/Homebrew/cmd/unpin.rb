#:  * `unpin` <formulae>:
#:    Unpin <formulae>, allowing them to be upgraded by `brew upgrade` <formulae>.
#:    See also `pin`.

require "formula"
require "cli_parser"

module Homebrew
  module_function

  def unpin_args
    Homebrew::CLI::Parser.new do
      usage_banner <<~EOS
        `unpin` <formulae>

        Unpin <formulae>, allowing them to be upgraded by `brew upgrade` <formulae>.
        See also `pin`.
      EOS
      switch :verbose
      switch :debug
    end
  end

  def unpin
    unpin_args.parse

    raise FormulaUnspecifiedError if args.remaining.empty?

    ARGV.resolved_formulae.each do |f|
      if f.pinned?
        f.unpin
      elsif !f.pinnable?
        onoe "#{f.name} not installed"
      else
        opoo "#{f.name} not pinned"
      end
    end
  end
end
