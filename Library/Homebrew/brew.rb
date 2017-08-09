unless ENV["HOMEBREW_BREW_FILE"]
  raise "HOMEBREW_BREW_FILE was not exported! Please call bin/brew directly!"
end

std_trap = trap("INT") { exit! 130 } # no backtrace thanks

# check ruby version before requiring any modules.
RUBY_TWO = RUBY_VERSION.split(".").first.to_i >= 2
raise "Homebrew must be run under Ruby 2!" unless RUBY_TWO

require "pathname"
HOMEBREW_LIBRARY_PATH = Pathname.new(__FILE__).realpath.parent
require "English"
unless $LOAD_PATH.include?(HOMEBREW_LIBRARY_PATH.to_s)
  $LOAD_PATH.unshift(HOMEBREW_LIBRARY_PATH.to_s)
end
require "global"
require "tap"

if ARGV == %w[--version] || ARGV == %w[-v]
  puts "Homebrew #{HOMEBREW_VERSION}"
  puts "Homebrew/homebrew-core #{CoreTap.instance.version_string}"
  exit 0
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

  path = PATH.new(ENV["PATH"])
  homebrew_path = PATH.new(ENV["HOMEBREW_PATH"])

  # Add contributed commands to PATH before checking.
  tap_cmds = Pathname.glob(Tap::TAP_DIRECTORY/"*/*/cmd")
  path.append(tap_cmds)
  homebrew_path.append(tap_cmds)

  # Add SCM wrappers.
  path.append(HOMEBREW_SHIMS_PATH/"scm")
  homebrew_path.append(HOMEBREW_SHIMS_PATH/"scm")

  ENV["PATH"] = path

  if cmd
    internal_cmd = require? HOMEBREW_LIBRARY_PATH/"cmd"/cmd

    unless internal_cmd
      internal_cmd = require? HOMEBREW_LIBRARY_PATH/"dev-cmd"/cmd
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

  # External commands expect a normal PATH
  ENV["PATH"] = homebrew_path unless internal_cmd

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
rescue Interrupt
  $stderr.puts # seemingly a newline is typical
  exit 130
rescue BuildError => e
  Utils::Analytics.report_build_error(e)
  e.dump
  exit 1
rescue RuntimeError, SystemCallError => e
  raise if e.message.empty?
  onoe e
  $stderr.puts e.backtrace if ARGV.debug?
  exit 1
rescue MethodDeprecatedError => e
  onoe e
  if e.issues_url
    $stderr.puts "If reporting this issue please do so at (not Homebrew/brew or Homebrew/core):"
    $stderr.puts "  #{Formatter.url(e.issues_url)}"
  end
  exit 1
rescue Exception => e
  onoe e
  if internal_cmd && defined?(OS::ISSUES_URL) &&
     !ENV["HOMEBREW_NO_AUTO_UPDATE"]
    $stderr.puts "#{Tty.bold}Please report this bug:#{Tty.reset}"
    $stderr.puts "  #{Formatter.url(OS::ISSUES_URL)}"
  end
  $stderr.puts e.backtrace
  exit 1
else
  exit 1 if Homebrew.failed?
end
