#:  * `commands` [`--quiet` [`--include-aliases`]]:
#:    Show a list of built-in and external commands.
#:
#:    If `--quiet` is passed, list only the names of commands without the header.
#:    With `--include-aliases`, the aliases of internal commands will be included.

module Homebrew
  module_function

  def commands
    if ARGV.include? "--quiet"
      cmds = internal_commands + external_commands
      cmds += internal_developer_commands
      cmds += HOMEBREW_INTERNAL_COMMAND_ALIASES.keys if ARGV.include? "--include-aliases"
      puts Formatter.columns(cmds.sort)
    else
      # Find commands in Homebrew/cmd
      puts "Built-in commands"
      puts Formatter.columns(internal_commands)

      # Find commands in Homebrew/dev-cmd
      puts
      puts "Built-in developer commands"
      puts Formatter.columns(internal_developer_commands)

      # Find commands in the path
      unless (exts = external_commands).empty?
        puts
        puts "External commands"
        puts Formatter.columns(exts)
      end
    end
  end

  def internal_commands
    find_internal_commands HOMEBREW_LIBRARY_PATH/"cmd"
  end

  def internal_developer_commands
    find_internal_commands HOMEBREW_LIBRARY_PATH/"dev-cmd"
  end

  def external_commands
    paths.each_with_object([]) do |path, cmds|
      Dir["#{path}/brew-*"].each do |file|
        next unless File.executable?(file)
        cmd = File.basename(file, ".rb")[5..-1]
        cmds << cmd unless cmd.include?(".")
      end
    end.sort
  end

  def find_internal_commands(directory)
    directory.children.each_with_object([]) do |f, cmds|
      cmds << f.basename.to_s.sub(/\.(?:rb|sh)$/, "") if f.file?
    end
  end
end
