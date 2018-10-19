require "emoji"
require "utils/analytics"
require "utils/curl"
require "utils/fork"
require "utils/formatter"
require "utils/git"
require "utils/github"
require "utils/inreplace"
require "utils/link"
require "utils/popen"
require "utils/svn"
require "utils/tty"
require "tap_constants"
require "time"

def require?(path)
  return false if path.nil?

  require path
  true
rescue LoadError => e
  # we should raise on syntax errors but not if the file doesn't exist.
  raise unless e.message.include?(path)
end

def ohai(title, *sput)
  title = Tty.truncate(title) if $stdout.tty? && !ARGV.verbose?
  puts Formatter.headline(title, color: :blue)
  puts sput
end

def odebug(title, *sput)
  return unless ARGV.debug?

  puts Formatter.headline(title, color: :magenta)
  puts sput unless sput.empty?
end

def oh1(title, options = {})
  if $stdout.tty? && !ARGV.verbose? && options.fetch(:truncate, :auto) == :auto
    title = Tty.truncate(title)
  end
  puts Formatter.headline(title, color: :green)
end

# Print a warning (do this rarely)
def opoo(message)
  $stderr.puts Formatter.warning(message, label: "Warning")
end

def onoe(message)
  $stderr.puts Formatter.error(message, label: "Error")
end

def ofail(error)
  onoe error
  Homebrew.failed = true
end

def odie(error)
  onoe error
  exit 1
end

def odeprecated(method, replacement = nil, disable: false, disable_on: nil, caller: send(:caller))
  replacement_message = if replacement
    "Use #{replacement} instead."
  else
    "There is no replacement."
  end

  unless disable_on.nil?
    if disable_on > Time.now
      will_be_disabled_message = " and will be disabled on #{disable_on.strftime("%Y-%m-%d")}"
    else
      disable = true
    end
  end

  verb = if disable
    "disabled"
  else
    "deprecated#{will_be_disabled_message}"
  end

  # Try to show the most relevant location in message, i.e. (if applicable):
  # - Location in a formula.
  # - Location outside of 'compat/'.
  # - Location of caller of deprecated method (if all else fails).
  backtrace = caller

  # Don't throw deprecations at all for cached, .brew or .metadata files.
  return if backtrace.any? do |line|
    line.include?(HOMEBREW_CACHE) ||
    line.include?("/.brew/") ||
    line.include?("/.metadata/")
  end

  tap_message = nil

  backtrace.each do |line|
    next unless match = line.match(HOMEBREW_TAP_PATH_REGEX)

    tap = Tap.fetch(match[:user], match[:repo])
    tap_message = "\nPlease report this to the #{tap} tap"
    tap_message += ", or even better, submit a PR to fix it" if replacement
    tap_message << ":\n  #{line.sub(/^(.*\:\d+)\:.*$/, '\1')}\n\n"
    break
  end

  message = "Calling #{method} is #{verb}! #{replacement_message}"
  message << tap_message if tap_message

  if ARGV.homebrew_developer? || disable || Homebrew.raise_deprecation_exceptions?
    exception = MethodDeprecatedError.new(message)
    exception.set_backtrace(backtrace)
    raise exception
  elsif !Homebrew.auditing?
    opoo message
  end
end

def odisabled(method, replacement = nil, options = {})
  options = { disable: true, caller: caller }.merge(options)
  odeprecated(method, replacement, options)
end

def pretty_installed(f)
  if !$stdout.tty?
    f.to_s
  elsif Emoji.enabled?
    "#{Tty.bold}#{f} #{Formatter.success("✔")}#{Tty.reset}"
  else
    Formatter.success("#{Tty.bold}#{f} (installed)#{Tty.reset}")
  end
end

def pretty_uninstalled(f)
  if !$stdout.tty?
    f.to_s
  elsif Emoji.enabled?
    "#{Tty.bold}#{f} #{Formatter.error("✘")}#{Tty.reset}"
  else
    Formatter.error("#{Tty.bold}#{f} (uninstalled)#{Tty.reset}")
  end
end

def pretty_duration(s)
  s = s.to_i
  res = ""

  if s > 59
    m = s / 60
    s %= 60
    res = "#{m} #{"minute".pluralize(m)}"
    return res if s.zero?

    res << " "
  end

  res << "#{s} #{"second".pluralize(s)}"
end

def interactive_shell(f = nil)
  unless f.nil?
    ENV["HOMEBREW_DEBUG_PREFIX"] = f.prefix
    ENV["HOMEBREW_DEBUG_INSTALL"] = f.full_name
  end

  if ENV["SHELL"].include?("zsh") && ENV["HOME"].start_with?(HOMEBREW_TEMP.resolved_path.to_s)
    FileUtils.mkdir_p ENV["HOME"]
    FileUtils.touch "#{ENV["HOME"]}/.zshrc"
  end

  Process.wait fork { exec ENV["SHELL"] }

  return if $CHILD_STATUS.success?
  raise "Aborted due to non-zero exit status (#{$CHILD_STATUS.exitstatus})" if $CHILD_STATUS.exited?

  raise $CHILD_STATUS.inspect
end

module Homebrew
  module_function

  def _system(cmd, *args, **options)
    pid = fork do
      yield if block_given?
      args.map!(&:to_s)
      begin
        exec(cmd, *args, **options)
      rescue
        nil
      end
      exit! 1 # never gets here unless exec failed
    end
    Process.wait(pid)
    $CHILD_STATUS.success?
  end

  def system(cmd, *args, **options)
    puts "#{cmd} #{args * " "}" if ARGV.verbose?
    _system(cmd, *args, **options)
  end

  def install_gem!(name, version = nil)
    # Match where our bundler gems are.
    ENV["GEM_HOME"] = "#{ENV["HOMEBREW_LIBRARY"]}/Homebrew/vendor/bundle/ruby/#{RbConfig::CONFIG["ruby_version"]}"
    ENV["GEM_PATH"] = ENV["GEM_HOME"]

    # Make rubygems notice env changes.
    Gem.clear_paths
    Gem::Specification.reset

    # Add Gem binary directory and (if missing) Ruby binary directory to PATH.
    path = PATH.new(ENV["PATH"])
    path.prepend(RUBY_BIN) if which("ruby") != RUBY_PATH
    path.prepend(Gem.bindir)
    ENV["PATH"] = path

    return unless Gem::Specification.find_all_by_name(name, version).empty?

    ohai "Installing or updating '#{name}' gem"
    install_args = %W[--no-ri --no-rdoc #{name}]
    install_args << "--version" << version if version

    # Do `gem install [...]` without having to spawn a separate process or
    # having to find the right `gem` binary for the running Ruby interpreter.
    require "rubygems/commands/install_command"
    install_cmd = Gem::Commands::InstallCommand.new
    install_cmd.handle_options(install_args)
    exit_code = 1 # Should not matter as `install_cmd.execute` always throws.
    begin
      install_cmd.execute
    rescue Gem::SystemExitException => e
      exit_code = e.exit_code
    end
    odie "Failed to install/update the '#{name}' gem." if exit_code.nonzero?
  end

  def install_gem_setup_path!(name, version = nil, executable = name)
    install_gem!(name, version)

    return if which(executable)

    odie <<~EOS
      The '#{name}' gem is installed but couldn't find '#{executable}' in the PATH:
      #{ENV["PATH"]}
    EOS
  end

  # rubocop:disable Style/GlobalVars
  def inject_dump_stats!(the_module, pattern)
    @injected_dump_stat_modules ||= {}
    @injected_dump_stat_modules[the_module] ||= []
    injected_methods = @injected_dump_stat_modules[the_module]
    the_module.module_eval do
      instance_methods.grep(pattern).each do |name|
        next if injected_methods.include? name

        method = instance_method(name)
        define_method(name) do |*args, &block|
          begin
            time = Time.now
            method.bind(self).call(*args, &block)
          ensure
            $times[name] ||= 0
            $times[name] += Time.now - time
          end
        end
      end
    end

    return unless $times.nil?

    $times = {}
    at_exit do
      col_width = [$times.keys.map(&:size).max + 2, 15].max
      $times.sort_by { |_k, v| v }.each do |method, time|
        puts format("%-*s %0.4f sec", col_width, "#{method}:", time)
      end
    end
  end
  # rubocop:enable Style/GlobalVars
end

def with_homebrew_path
  with_env(PATH: PATH.new(ENV["HOMEBREW_PATH"])) do
    yield
  end
end

def with_custom_locale(locale)
  with_env(LC_ALL: locale) do
    yield
  end
end

# Kernel.system but with exceptions
def safe_system(cmd, *args, **options)
  return if Homebrew.system(cmd, *args, **options)

  raise(ErrorDuringExecution.new([cmd, *args], status: $CHILD_STATUS))
end

# Prints no output
def quiet_system(cmd, *args)
  Homebrew._system(cmd, *args) do
    # Redirect output streams to `/dev/null` instead of closing as some programs
    # will fail to execute if they can't write to an open stream.
    $stdout.reopen("/dev/null")
    $stderr.reopen("/dev/null")
  end
end

def which(cmd, path = ENV["PATH"])
  PATH.new(path).each do |p|
    begin
      pcmd = File.expand_path(cmd, p)
    rescue ArgumentError
      # File.expand_path will raise an ArgumentError if the path is malformed.
      # See https://github.com/Homebrew/legacy-homebrew/issues/32789
      next
    end
    return Pathname.new(pcmd) if File.file?(pcmd) && File.executable?(pcmd)
  end
  nil
end

def which_all(cmd, path = ENV["PATH"])
  PATH.new(path).map do |p|
    begin
      pcmd = File.expand_path(cmd, p)
    rescue ArgumentError
      # File.expand_path will raise an ArgumentError if the path is malformed.
      # See https://github.com/Homebrew/legacy-homebrew/issues/32789
      next
    end
    Pathname.new(pcmd) if File.file?(pcmd) && File.executable?(pcmd)
  end.compact.uniq
end

def which_editor
  editor = ENV.values_at("HOMEBREW_EDITOR", "HOMEBREW_VISUAL")
              .compact
              .reject(&:empty?)
              .first
  return editor if editor

  # Find Atom, Sublime Text, Textmate, BBEdit / TextWrangler, or vim
  editor = %w[atom subl mate edit vim].find do |candidate|
    candidate if which(candidate, ENV["HOMEBREW_PATH"])
  end
  editor ||= "vim"

  opoo <<~EOS
    Using #{editor} because no editor was set in the environment.
    This may change in the future, so we recommend setting EDITOR,
    or HOMEBREW_EDITOR to your preferred text editor.
  EOS

  editor
end

def exec_editor(*args)
  puts "Editing #{args.join "\n"}"
  with_homebrew_path { safe_exec(which_editor, *args) }
end

def exec_browser(*args)
  browser = ENV["HOMEBREW_BROWSER"]
  browser ||= OS::PATH_OPEN if defined?(OS::PATH_OPEN)
  return unless browser

  safe_exec(browser, *args)
end

def safe_exec(cmd, *args)
  # This buys us proper argument quoting and evaluation
  # of environment variables in the cmd parameter.
  exec "/bin/sh", "-c", "#{cmd} \"$@\"", "--", *args
end

# GZips the given paths, and returns the gzipped paths
def gzip(*paths)
  paths.map do |path|
    safe_system "gzip", path
    Pathname.new("#{path}.gz")
  end
end

# Returns array of architectures that the given command or library is built for.
def archs_for_command(cmd)
  cmd = which(cmd) unless Pathname.new(cmd).absolute?
  Pathname.new(cmd).archs
end

def ignore_interrupts(opt = nil)
  std_trap = trap("INT") do
    puts "One sec, just cleaning up" unless opt == :quietly
  end
  yield
ensure
  trap("INT", std_trap)
end

def capture_stderr
  old = $stderr
  $stderr = StringIO.new
  yield
  $stderr.string
ensure
  $stderr = old
end

def nostdout
  if ARGV.verbose?
    yield
  else
    begin
      out = $stdout.dup
      $stdout.reopen("/dev/null")
      yield
    ensure
      $stdout.reopen(out)
      out.close
    end
  end
end

def paths
  @paths ||= PATH.new(ENV["HOMEBREW_PATH"]).map do |p|
    begin
      File.expand_path(p).chomp("/")
    rescue ArgumentError
      onoe "The following PATH component is invalid: #{p}"
    end
  end.uniq.compact
end

def disk_usage_readable(size_in_bytes)
  if size_in_bytes >= 1_073_741_824
    size = size_in_bytes.to_f / 1_073_741_824
    unit = "GB"
  elsif size_in_bytes >= 1_048_576
    size = size_in_bytes.to_f / 1_048_576
    unit = "MB"
  elsif size_in_bytes >= 1_024
    size = size_in_bytes.to_f / 1_024
    unit = "KB"
  else
    size = size_in_bytes
    unit = "B"
  end

  # avoid trailing zero after decimal point
  if ((size * 10).to_i % 10).zero?
    "#{size.to_i}#{unit}"
  else
    "#{format("%.1f", size)}#{unit}"
  end
end

def number_readable(number)
  numstr = number.to_i.to_s
  (numstr.size - 3).step(1, -3) { |i| numstr.insert(i, ",") }
  numstr
end

# Truncates a text string to fit within a byte size constraint,
# preserving character encoding validity. The returned string will
# be not much longer than the specified max_bytes, though the exact
# shortfall or overrun may vary.
def truncate_text_to_approximate_size(s, max_bytes, options = {})
  front_weight = options.fetch(:front_weight, 0.5)
  if front_weight < 0.0 || front_weight > 1.0
    raise "opts[:front_weight] must be between 0.0 and 1.0"
  end
  return s if s.bytesize <= max_bytes

  glue = "\n[...snip...]\n"
  max_bytes_in = [max_bytes - glue.bytesize, 1].max
  bytes = s.dup.force_encoding("BINARY")
  glue_bytes = glue.encode("BINARY")
  n_front_bytes = (max_bytes_in * front_weight).floor
  n_back_bytes = max_bytes_in - n_front_bytes
  if n_front_bytes.zero?
    front = bytes[1..0]
    back = bytes[-max_bytes_in..-1]
  elsif n_back_bytes.zero?
    front = bytes[0..(max_bytes_in - 1)]
    back = bytes[1..0]
  else
    front = bytes[0..(n_front_bytes - 1)]
    back = bytes[-n_back_bytes..-1]
  end
  out = front + glue_bytes + back
  out.force_encoding("UTF-8")
  out.encode!("UTF-16", invalid: :replace)
  out.encode!("UTF-8")
  out
end

# Calls the given block with the passed environment variables
# added to ENV, then restores ENV afterwards.
# Example:
# <pre>with_env(PATH: "/bin") do
#   system "echo $PATH"
# end</pre>
#
# Note that this method is *not* thread-safe - other threads
# which happen to be scheduled during the block will also
# see these environment variables.
def with_env(hash)
  old_values = {}
  begin
    hash.each do |key, value|
      key = key.to_s
      old_values[key] = ENV.delete(key)
      ENV[key] = value
    end

    yield if block_given?
  ensure
    ENV.update(old_values)
  end
end

def shell_profile
  Utils::Shell.profile
end

def tap_and_name_comparison
  proc do |a, b|
    if a.include?("/") && !b.include?("/")
      1
    elsif !a.include?("/") && b.include?("/")
      -1
    else
      a <=> b
    end
  end
end

def command_help_lines(path)
  path.read.lines.grep(/^#:/).map { |line| line.slice(2..-1) }
end
