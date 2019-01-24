#:  * `config`:
#:    Show Homebrew and system configuration useful for debugging. If you file
#:    a bug report, you will likely be asked for this information if you do not
#:    provide it.

require "system_config"
require "cli_parser"

module Homebrew
  module_function

  def config_args
    Homebrew::CLI::Parser.new do
      usage_banner <<~EOS
        `config`

        Show Homebrew and system configuration useful for debugging. If you file
        a bug report, you will likely be asked for this information if you do not
        provide it.
      EOS
      switch :verbose
      switch :debug
    end
  end

  def config
    config_args.parse
    raise UsageError unless args.remaining.empty?
    SystemConfig.dump_verbose_config
  end
end
