unless ENV["HOMEBREW_BREW_FILE"]
  raise "HOMEBREW_BREW_FILE was not exported! Please call bin/brew directly!"
end

std_trap = trap("INT") { exit! 130 } # no backtrace thanks

# check ruby version before requiring any modules.
RUBY_TWO = RUBY_VERSION.split(".").first.to_i >= 2
raise "Homebrew must be run under Ruby 2!" unless RUBY_TWO

require "pathname"
HOMEBREW_LIBRARY_PATH = Pathname.new(__FILE__).realpath.parent
$:.unshift(HOMEBREW_LIBRARY_PATH.to_s)
require "global"

if ARGV == %w[--version] || ARGV == %w[-v]
  require "tap"
  puts "Homebrew #{HOMEBREW_VERSION}"
  puts "Homebrew/homebrew-core #{CoreTap.instance.version_string}"
  exit 0
end

def require?(path)
  require path
rescue LoadError => e
  # HACK: ( because we should raise on syntax errors but
  # not if the file doesn't exist. TODO make robust!
  raise unless e.to_s.include? path
end

begin
  trap("INT", std_trap) # restore default CTRL-C handler

  empty_argv = ARGV.empty?
  help_flag_list = %w[-h --help --usage -?]
  help_flag = !ENV["HOMEBREW_HELP"].nil?
  internal_cmd = true
  cmd = nil

  ARGV.dup.each_with_index do |arg, i|
    break if help_flag && cmd

    if arg == "help" && !cmd
      # Command-style help: `help <cmd>` is fine, but `<cmd> help` is not.
      help_flag = true
    elsif !cmd && !help_flag_list.include?(arg)
      cmd = ARGV.delete_at(i)
    end
  end

  # Add contributed commands to PATH before checking.
  Dir["#{HOMEBREW_LIBRARY}/Taps/*/*/cmd"].each do |tap_cmd_dir|
    ENV["PATH"] += "#{File::PATH_SEPARATOR}#{tap_cmd_dir}"
  end

  # Add cask commands to PATH.
  ENV["PATH"] += "#{File::PATH_SEPARATOR}#{HOMEBREW_LIBRARY}/Homebrew/cask/cmd"

  # Add SCM wrappers.
  ENV["PATH"] += "#{File::PATH_SEPARATOR}#{HOMEBREW_SHIMS_PATH}/scm"

  if cmd
    internal_cmd = require? HOMEBREW_LIBRARY_PATH.join("cmd", cmd)

    unless internal_cmd
      internal_cmd = require? HOMEBREW_LIBRARY_PATH.join("dev-cmd", cmd)
      if internal_cmd && !ARGV.homebrew_developer?
        system "git", "config", "--file=#{HOMEBREW_REPOSITORY}/.git/config",
                                "--replace-all", "homebrew.devcmdrun", "true"
        ENV["HOMEBREW_DEV_CMD_RUN"] = "1"
      end
    end
  end

  # Usage instructions should be displayed if and only if one of:
  # - a help flag is passed AND a command is matched
  # - a help flag is passed AND there is no command specified
  # - no arguments are passed
  if empty_argv || help_flag
    require "cmd/help"
    Homebrew.help cmd, empty_argv: empty_argv
    # `Homebrew.help` never returns, except for external/unknown commands.
  end

  # Migrate LinkedKegs/PinnedKegs if update didn't already do so
  migrate_legacy_keg_symlinks_if_necessary

  # Uninstall old brew-cask if it's still around; we just use the tap now.
  if cmd == "cask" && (HOMEBREW_CELLAR/"brew-cask").exist?
    system(HOMEBREW_BREW_FILE, "uninstall", "--force", "brew-cask")
  end

  if internal_cmd
    Homebrew.send cmd.to_s.tr("-", "_").downcase
  elsif which "brew-#{cmd}"
    %w[CACHE LIBRARY_PATH].each do |e|
      ENV["HOMEBREW_#{e}"] = Object.const_get("HOMEBREW_#{e}").to_s
    end
    exec "brew-#{cmd}", *ARGV
  elsif (path = which("brew-#{cmd}.rb")) && require?(path)
    exit Homebrew.failed? ? 1 : 0
  else
    require "tap"
    possible_tap = OFFICIAL_CMD_TAPS.find { |_, cmds| cmds.include?(cmd) }
    possible_tap = Tap.fetch(possible_tap.first) if possible_tap

    if possible_tap && !possible_tap.installed?
      brew_uid = HOMEBREW_BREW_FILE.stat.uid
      tap_commands = []
      if Process.uid.zero? && !brew_uid.zero?
        tap_commands += %W[/usr/bin/sudo -u ##{brew_uid}]
      end
      tap_commands += %W[#{HOMEBREW_BREW_FILE} tap #{possible_tap}]
      safe_system(*tap_commands)
      exec HOMEBREW_BREW_FILE, cmd, *ARGV
    else
      odie "Unknown command: #{cmd}"
    end
  end

rescue UsageError => e
  require "cmd/help"
  Homebrew.help cmd, usage_error: e.message
rescue SystemExit => e
  onoe "Kernel.exit" if ARGV.verbose? && !e.success?
  $stderr.puts e.backtrace if ARGV.debug?
  raise
rescue Interrupt => e
  $stderr.puts # seemingly a newline is typical
  exit 130
rescue BuildError => e
  Utils::Analytics.report_exception(e)
  e.dump
  exit 1
rescue RuntimeError, SystemCallError => e
  Utils::Analytics.report_exception(e)
  raise if e.message.empty?
  onoe e
  $stderr.puts e.backtrace if ARGV.debug?
  exit 1
rescue Exception => e
  Utils::Analytics.report_exception(e)
  onoe e
  if internal_cmd && defined?(OS::ISSUES_URL)
    $stderr.puts "#{Tty.bold}Please report this bug:#{Tty.reset}"
    $stderr.puts "  #{Formatter.url(OS::ISSUES_URL)}"
  end
  $stderr.puts e.backtrace
  exit 1
else
  exit 1 if Homebrew.failed?
end
