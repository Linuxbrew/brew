#:  * `command` <cmd>:
#:    Display the path to the file which is used when invoking `brew` <cmd>.

require "commands"

module Homebrew
  module_function

  def command
    abort "This command requires a command argument" if ARGV.empty?
    cmd = ARGV.first
    cmd = HOMEBREW_INTERNAL_COMMAND_ALIASES.fetch(cmd, cmd)

    if (path = Commands.path(cmd))
      puts path
    elsif (path = which("brew-#{cmd}") || which("brew-#{cmd}.rb"))
      puts path
    else
      odie "Unknown command: #{cmd}"
    end
  end
end
