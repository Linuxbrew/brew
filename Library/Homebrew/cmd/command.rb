#:  * `command` <cmd>:
#:    Display the path to the file which is used when invoking `brew` <cmd>.

require "commands"

module Homebrew
  module_function

  def command
    abort "This command requires a command argument" if ARGV.empty?

    cmd = HOMEBREW_INTERNAL_COMMAND_ALIASES.fetch(ARGV.first, ARGV.first)

    path = Commands.path(cmd)

    cmd_paths = PATH.new(ENV["PATH"]).append(Tap.cmd_directories) unless path
    path ||= which("brew-#{cmd}", cmd_paths)
    path ||= which("brew-#{cmd}.rb", cmd_paths)

    odie "Unknown command: #{cmd}" unless path
    puts path
  end
end
