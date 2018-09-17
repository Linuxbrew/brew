#:  * `commands` [`--quiet` [`--include-aliases`]]:
#:    Show a list of built-in and external commands.
#:
#:    If `--quiet` is passed, list only the names of commands without the header.
#:    With `--include-aliases`, the aliases of internal commands will be included.

module Homebrew
  module_function

  def commands
    if ARGV.include? "--quiet"
      cmds = internal_commands
      cmds += external_commands
      cmds += internal_developer_commands
      cmds += HOMEBREW_INTERNAL_COMMAND_ALIASES.keys if ARGV.include? "--include-aliases"
      puts Formatter.columns(cmds.sort)
      return
    end

    # Find commands in Homebrew/cmd
    puts "Built-in commands"
    puts Formatter.columns(internal_commands.sort)

    # Find commands in Homebrew/dev-cmd
    puts
    puts "Built-in developer commands"
    puts Formatter.columns(internal_developer_commands.sort)

    exts = external_commands
    return if exts.empty?

    # Find commands in the PATH
    puts
    puts "External commands"
    puts Formatter.columns(exts)
  end

  def internal_commands
    find_internal_commands HOMEBREW_LIBRARY_PATH/"cmd"
  end

  def internal_developer_commands
    find_internal_commands HOMEBREW_LIBRARY_PATH/"dev-cmd"
  end

  def external_commands
    cmd_paths = PATH.new(ENV["PATH"]).append(Tap.cmd_directories)
    cmd_paths.each_with_object([]) do |path, cmds|
      Dir["#{path}/brew-*"].each do |file|
        next unless File.executable?(file)

        cmd = File.basename(file, ".rb")[5..-1]
        next if cmd.include?(".")

        cmds << cmd
      end
    end.sort
  end

  def find_internal_commands(directory)
    Pathname.glob(directory/"*")
            .select(&:file?)
            .map { |f| f.basename.to_s.sub(/\.(?:rb|sh)$/, "") }
  end
end
