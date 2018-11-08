#:  * `style` [`--fix`] [`--display-cop-names`] [`--only-cops=`<cops>|`--except-cops=`<cops>] [<files>|<taps>|<formulae>]:
#:    Check formulae or files for conformance to Homebrew style guidelines.
#:
#:    Lists of <files>, <taps> and <formulae> may not be combined. If none are
#:    provided, `style` will run style checks on the whole Homebrew library,
#:    including core code and all formulae.
#:
#:    If `--fix` is passed, automatically fix style violations using RuboCop's
#:    auto-correct feature.
#:
#:    If `--display-cop-names` is passed, include the RuboCop cop name for each
#:    violation in the output.
#:
#:    Passing `--only-cops=`<cops> will check for violations of only the listed
#:    RuboCop <cops>, while `--except-cops=`<cops> will skip checking the listed
#:    <cops>. For either option <cops> should be a comma-separated list of cop names.
#:
#:    Exits with a non-zero status if any style violations are found.

require "json"
require "open3"
require "style"
require "cli_parser"

module Homebrew
  module_function

  def style_args
    Homebrew::CLI::Parser.new do
      usage_banner <<~EOS
        `style` [<options>] [<files>|<taps>|<formulae>]

        Check formulae or files for conformance to Homebrew style guidelines.

        Lists of <files>, <taps> and <formulae> may not be combined. If none are
        provided, `style` will run style checks on the whole Homebrew library,
        including core code and all formulae.
      EOS
      switch "--fix",
        description: "Fix style violations automatically using RuboCop's auto-correct feature."
      switch "--display-cop-names",
        description: "Include the RuboCop cop name for each violation in the output."
      comma_array "--only-cops",
        description: "Specify a comma-separated <cops> list to check for violations of only the "\
                     "listed RuboCop cops."
      comma_array "--except-cops",
        description: "Specify a comma-separated <cops> list to skip checking for violations of the "\
                     "listed RuboCop cops."
      switch :verbose
      switch :debug
      conflicts "--only-cops", "--except-cops"
    end
  end

  def style
    style_args.parse

    target = if ARGV.named.empty?
      nil
    elsif ARGV.named.any? { |file| File.exist? file }
      ARGV.named
    elsif ARGV.named.any? { |tap| tap.count("/") == 1 }
      ARGV.named.map { |tap| Tap.fetch(tap).path }
    else
      ARGV.formulae.map(&:path)
    end

    only_cops = args.only_cops
    except_cops = args.except_cops

    options = { fix: args.fix? }
    if only_cops
      options[:only_cops] = only_cops
    elsif except_cops
      options[:except_cops] = except_cops
    elsif only_cops.nil? && except_cops.nil?
      options[:except_cops] = %w[FormulaAudit
                                 FormulaAuditStrict
                                 NewFormulaAudit]
    end

    Homebrew.failed = Style.check_style_and_print(target, options)
  end
end
