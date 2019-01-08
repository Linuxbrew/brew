#:  * `prune` [`--dry-run`]:
#:    Deprecated. Use `brew cleanup` instead.

require "keg"
require "cli_parser"
require "cleanup"

module Homebrew
  module_function

  def prune_args
    Homebrew::CLI::Parser.new do
      usage_banner <<~EOS
        `prune` [<options>]

        Deprecated. Use `brew cleanup` instead.
      EOS
      switch "-n", "--dry-run",
        description: "Show what would be removed, but do not actually remove anything."
      switch :verbose
      switch :debug
    end
  end

  def prune
    prune_args.parse

    odeprecated("'brew prune'", "'brew cleanup'")
    Cleanup.new(dry_run: args.dry_run?).prune_prefix_symlinks_and_directories
  end
end
