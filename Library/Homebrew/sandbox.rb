require "erb"
require "tempfile"

class Sandbox
  SANDBOX_EXEC = "/usr/bin/sandbox-exec".freeze
  SANDBOXED_TAPS = %w[
    homebrew/core
    homebrew/dupes
    homebrew/fuse
    homebrew/devel-only
    homebrew/tex
  ].freeze

  def self.available?
    OS.mac? && OS::Mac.version >= "10.6" && File.executable?(SANDBOX_EXEC)
  end

  def self.formula?(formula)
    return false unless available?
    return false if ARGV.no_sandbox?
    ARGV.sandbox? || SANDBOXED_TAPS.include?(formula.tap.to_s)
  end

  def self.test?
    return false unless available?
    !ARGV.no_sandbox?
  end

  def self.print_sandbox_message
    return if @printed_sandbox_message
    ohai "Using the sandbox"
    @printed_sandbox_message = true
  end

  def initialize
    @profile = SandboxProfile.new
  end

  def record_log(file)
    @logfile = file
  end

  def add_rule(rule)
    @profile.add_rule(rule)
  end

  def allow_write(path, options = {})
    add_rule allow: true, operation: "file-write*", filter: path_filter(path, options[:type])
  end

  def deny_write(path, options = {})
    add_rule allow: false, operation: "file-write*", filter: path_filter(path, options[:type])
  end

  def allow_write_path(path)
    allow_write path, type: :subpath
  end

  def deny_write_path(path)
    deny_write path, type: :subpath
  end

  def allow_write_temp_and_cache
    allow_write_path "/private/tmp"
    allow_write_path "/private/var/tmp"
    allow_write "^/private/var/folders/[^/]+/[^/]+/[C,T]/", type: :regex
    allow_write_path HOMEBREW_TEMP
    allow_write_path HOMEBREW_CACHE
  end

  def allow_write_cellar(formula)
    allow_write_path formula.rack
    allow_write_path formula.etc
    allow_write_path formula.var
  end

  # Xcode projects expect access to certain cache/archive dirs.
  def allow_write_xcode
    allow_write_path "/Users/#{ENV["USER"]}/Library/Developer"
  end

  def allow_write_log(formula)
    allow_write_path formula.logs
  end

  def deny_write_homebrew_repository
    deny_write HOMEBREW_BREW_FILE
    if HOMEBREW_PREFIX.to_s != HOMEBREW_REPOSITORY.to_s
      deny_write_path HOMEBREW_REPOSITORY
    else
      deny_write_path HOMEBREW_LIBRARY
      deny_write_path HOMEBREW_REPOSITORY/".git"
    end
  end

  def exec(*args)
    seatbelt = Tempfile.new(["homebrew", ".sb"], HOMEBREW_TEMP)
    seatbelt.write(@profile.dump)
    seatbelt.close
    @start = Time.now
    safe_system SANDBOX_EXEC, "-f", seatbelt.path, *args
  rescue
    @failed = true
    raise
  ensure
    seatbelt.unlink
    sleep 0.1 # wait for a bit to let syslog catch up the latest events.
    syslog_args = %W[
      -F $((Time)(local))\ $(Sender)[$(PID)]:\ $(Message)
      -k Time ge #{@start.to_i}
      -k Message S deny
      -k Sender kernel
      -o
      -k Time ge #{@start.to_i}
      -k Message S deny
      -k Sender sandboxd
    ]
    logs = Utils.popen_read("syslog", *syslog_args)

    # These messages are confusing and non-fatal, so don't report them.
    logs = logs.lines.reject { |l| l.match(/^.*Python\(\d+\) deny file-write.*pyc$/) }.join

    unless logs.empty?
      if @logfile
        log = open(@logfile, "w")
        log.write logs
        log.write "\nWe use time to filter sandbox log. Therefore, unrelated logs may be recorded.\n"
        log.close
      end

      if @failed && ARGV.verbose?
        ohai "Sandbox log"
        puts logs
        $stdout.flush # without it, brew test-bot would fail to catch the log
      end
    end
  end

  private

  def expand_realpath(path)
    raise unless path.absolute?
    path.exist? ? path.realpath : expand_realpath(path.parent)/path.basename
  end

  def path_filter(path, type)
    case type
    when :regex        then "regex \#\"#{path}\""
    when :subpath      then "subpath \"#{expand_realpath(Pathname.new(path))}\""
    when :literal, nil then "literal \"#{expand_realpath(Pathname.new(path))}\""
    end
  end

  class SandboxProfile
    SEATBELT_ERB = <<-EOS.undent
      (version 1)
      (debug deny) ; log all denied operations to /var/log/system.log
      <%= rules.join("\n") %>
      (allow file-write*
          (literal "/dev/ptmx")
          (literal "/dev/dtracehelper")
          (literal "/dev/null")
          (literal "/dev/zero")
          (regex #"^/dev/fd/[0-9]+$")
          (regex #"^/dev/ttys?[0-9]*$")
          )
      (deny file-write*) ; deny non-whitelist file write operations
      (allow process-exec
          (literal "/bin/ps")
          (with no-sandbox)
          ) ; allow certain processes running without sandbox
      (allow default) ; allow everything else
    EOS

    attr_reader :rules

    def initialize
      @rules = []
    end

    def add_rule(rule)
      s = "("
      s << (rule[:allow] ? "allow": "deny")
      s << " #{rule[:operation]}"
      s << " (#{rule[:filter]})" if rule[:filter]
      s << " (with #{rule[:modifier]})" if rule[:modifier]
      s << ")"
      @rules << s
    end

    def dump
      ERB.new(SEATBELT_ERB).result(binding)
    end
  end
end
