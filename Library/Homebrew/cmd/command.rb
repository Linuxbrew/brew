#:  * `command` <cmd>:
#:    Display the path to the file which is used when invoking `brew` <cmd>.

module Homebrew
  def command
    abort "This command requires a command argument" if ARGV.empty?
    cmd = ARGV.first
    cmd = HOMEBREW_INTERNAL_COMMAND_ALIASES.fetch(cmd, cmd)

    if (path = internal_command_path cmd)
      puts path
    elsif (path = which("brew-#{cmd}") || which("brew-#{cmd}.rb"))
      puts path
    else
      odie "Unknown command: #{cmd}"
    end
  end

  private

  def internal_command_path(cmd)
    extensions = %w[rb sh]
    paths = extensions.map { |ext| HOMEBREW_LIBRARY_PATH/"cmd/#{cmd}.#{ext}" }
    paths += extensions.map { |ext| HOMEBREW_LIBRARY_PATH/"dev-cmd/#{cmd}.#{ext}" }
    paths.find { |p| p.file? }
  end
end
