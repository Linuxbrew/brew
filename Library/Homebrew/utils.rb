require "pathname"
require "emoji"
require "exceptions"
require "utils/analytics"
require "utils/curl"
require "utils/fork"
require "utils/formatter"
require "utils/git"
require "utils/github"
require "utils/hash"
require "utils/inreplace"
require "utils/link"
require "utils/popen"
require "utils/svn"
require "utils/tty"
require "time"

def require?(path)
  return false if path.nil?
  require path
rescue LoadError => e
  # we should raise on syntax errors but not if the file doesn't exist.
  raise unless e.message.include?(path)
end

def ohai(title, *sput)
  title = Tty.truncate(title) if $stdout.tty? && !ARGV.verbose?
  puts Formatter.headline(title, color: :blue)
  puts sput
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
  tap_message = nil
  caller_message = backtrace.detect do |line|
    next unless line =~ %r{^#{Regexp.escape(HOMEBREW_LIBRARY)}/Taps/([^/]+/[^/]+)/}
    tap = Tap.fetch Regexp.last_match(1)
    tap_message = "\nPlease report this to the #{tap} tap!"
    true
  end
  caller_message ||= backtrace.detect do |line|
    !line.start_with?("#{HOMEBREW_LIBRARY_PATH}/compat/")
  end
  caller_message ||= backtrace[1]

  message = <<-EOS.undent
    Calling #{method} is #{verb}!
    #{replacement_message}
    #{caller_message}#{tap_message}
  EOS

  if ARGV.homebrew_developer? || disable ||
     Homebrew.raise_deprecation_exceptions?
    raise MethodDeprecatedError, message
  else
    opoo "#{message}\n"
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
    res = Formatter.pluralize(m, "minute")
    return res if s.zero?
    res << " "
  end

  res << Formatter.pluralize(s, "second")
end

def interactive_shell(f = nil)
  unless f.nil?
    ENV["HOMEBREW_DEBUG_PREFIX"] = f.prefix
    ENV["HOMEBREW_DEBUG_INSTALL"] = f.full_name
  end

  if ENV["SHELL"].include?("zsh") && ENV["HOME"].start_with?(HOMEBREW_TEMP.resolved_path.to_s)
    FileUtils.touch "#{ENV["HOME"]}/.zshrc"
  end

  Process.wait fork { exec ENV["SHELL"] }

  return if $CHILD_STATUS.success?
  raise "Aborted due to non-zero exit status (#{$CHILD_STATUS.exitstatus})" if $CHILD_STATUS.exited?
  raise $CHILD_STATUS.inspect
end

module Homebrew
  module_function

  def _system(cmd, *args)
    pid = fork do
      yield if block_given?
      args.collect!(&:to_s)
      begin
        exec(cmd, *args)
      rescue
        nil
      end
      exit! 1 # never gets here unless exec failed
    end
    Process.wait(pid)
    $CHILD_STATUS.success?
  end

  def system(cmd, *args)
    puts "#{cmd} #{args * " "}" if ARGV.verbose?
    _system(cmd, *args)
  end

  def install_gem_setup_path!(name, version = nil, executable = name)
    # Respect user's preferences for where gems should be installed.
    ENV["GEM_HOME"] = ENV["GEM_OLD_HOME"].to_s
    ENV["GEM_HOME"] = Gem.user_dir if ENV["GEM_HOME"].empty?
    ENV["GEM_PATH"] = ENV["GEM_OLD_PATH"] unless ENV["GEM_OLD_PATH"].to_s.empty?

    # Make rubygems notice env changes.
    Gem.clear_paths
    Gem::Specification.reset

    # Add Gem binary directory and (if missing) Ruby binary directory to PATH.
    path = PATH.new(ENV["PATH"])
    path.prepend(RUBY_BIN) if which("ruby") != RUBY_PATH
    path.prepend(Gem.bindir)
    ENV["PATH"] = path

    if Gem::Specification.find_all_by_name(name, version).empty?
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

    return if which(executable)
    odie <<-EOS.undent
      The '#{name}' gem is installed but couldn't find '#{executable}' in the PATH:
      #{ENV["PATH"]}
    EOS
  end

  # Hash of Module => Set(method_names)
  @injected_dump_stat_modules = {}

  def inject_dump_stats!(the_module, pattern)
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
end

def with_system_path
  old_path = ENV["PATH"]
  ENV["PATH"] = "/usr/bin:/bin"
  yield
ensure
  ENV["PATH"] = old_path
end

def with_homebrew_path
  old_path = ENV["PATH"]
  ENV["PATH"] = ENV["HOMEBREW_PATH"]
  yield
ensure
  ENV["PATH"] = old_path
end

def with_custom_locale(locale)
  old_locale = ENV["LC_ALL"]
  ENV["LC_ALL"] = locale
  yield
ensure
  ENV["LC_ALL"] = old_locale
end

def run_as_not_developer(&_block)
  with_env "HOMEBREW_DEVELOPER" => nil do
    yield
  end
end

# Kernel.system but with exceptions
def safe_system(cmd, *args)
  Homebrew.system(cmd, *args) || raise(ErrorDuringExecution.new(cmd, args))
end

# prints no output
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
  editor ||= "/usr/bin/vim"

  opoo <<-EOS.undent
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
  paths.collect do |path|
    with_system_path { safe_system "gzip", path }
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

def paths(env_path = ENV["PATH"])
  @paths ||= PATH.new(env_path).collect do |p|
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

def migrate_legacy_keg_symlinks_if_necessary
  legacy_linked_kegs = HOMEBREW_LIBRARY/"LinkedKegs"
  return unless legacy_linked_kegs.directory?

  HOMEBREW_LINKED_KEGS.mkpath unless legacy_linked_kegs.children.empty?
  legacy_linked_kegs.children.each do |link|
    name = link.basename.to_s
    src = begin
      link.realpath
    rescue Errno::ENOENT
      begin
        (HOMEBREW_PREFIX/"opt/#{name}").realpath
      rescue Errno::ENOENT
        begin
          Formulary.factory(name).installed_prefix
        rescue
          next
        end
      end
    end
    dst = HOMEBREW_LINKED_KEGS/name
    dst.unlink if dst.exist?
    FileUtils.ln_sf(src.relative_path_from(dst.parent), dst)
  end
  FileUtils.rm_rf legacy_linked_kegs

  legacy_pinned_kegs = HOMEBREW_LIBRARY/"PinnedKegs"
  return unless legacy_pinned_kegs.directory?

  HOMEBREW_PINNED_KEGS.mkpath unless legacy_pinned_kegs.children.empty?
  legacy_pinned_kegs.children.each do |link|
    name = link.basename.to_s
    src = link.realpath
    dst = HOMEBREW_PINNED_KEGS/name
    FileUtils.ln_sf(src.relative_path_from(dst.parent), dst)
  end
  FileUtils.rm_rf legacy_pinned_kegs
end

# Calls the given block with the passed environment variables
# added to ENV, then restores ENV afterwards.
# Example:
# with_env "PATH" => "/bin" do
#   system "echo $PATH"
# end
#
# Note that this method is *not* thread-safe - other threads
# which happen to be scheduled during the block will also
# see these environment variables.
def with_env(hash)
  old_values = {}
  begin
    hash.each do |key, value|
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
