#:  * `command` <cmd>:
#:    Display the path to the file which is used when invoking `brew` <cmd>.

require "commands"
require "cli_parser"

module Homebrew
  module_function

  def command_args
    Homebrew::CLI::Parser.new do
      usage_banner <<~EOS
        `command` <cmd>

        Display the path to the file which is used when invoking `brew` <cmd>.
      EOS
      switch :verbose
      switch :debug
    end
  end

  def command
    command_args.parse
    abort "This command requires a command argument" if args.remaining.empty?

    cmd = HOMEBREW_INTERNAL_COMMAND_ALIASES.fetch(args.remaining.first, args.remaining.first)

    path = Commands.path(cmd)

    cmd_paths = PATH.new(ENV["PATH"]).append(Tap.cmd_directories) unless path
    path ||= which("brew-#{cmd}", cmd_paths)
    path ||= which("brew-#{cmd}.rb", cmd_paths)

    odie "Unknown command: #{cmd}" unless path
    puts path
  end
end
