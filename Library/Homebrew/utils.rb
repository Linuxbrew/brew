require "pathname"
require "emoji"
require "exceptions"
require "utils/hash"
require "utils/json"
require "utils/inreplace"
require "utils/popen"
require "utils/fork"
require "utils/git"
require "utils/analytics"
require "utils/github"
require "utils/curl"

class Tty
  class << self
    def strip_ansi(string)
      string.gsub(/\033\[\d+(;\d+)*m/, "")
    end

    def blue
      bold 34
    end

    def white
      bold 39
    end

    def magenta
      bold 35
    end

    def red
      underline 31
    end

    def yellow
      underline 33
    end

    def reset
      escape 0
    end

    def em
      underline 39
    end

    def green
      bold 32
    end

    def gray
      bold 30
    end

    def highlight
      bold 39
    end

    def width
      `/usr/bin/tput cols`.strip.to_i
    end

    def truncate(str)
      w = width
      w > 10 ? str.to_s[0, w - 4] : str
    end

    private

    def color(n)
      escape "0;#{n}"
    end

    def bold(n)
      escape "1;#{n}"
    end

    def underline(n)
      escape "4;#{n}"
    end

    def escape(n)
      "\033[#{n}m" if $stdout.tty?
    end
  end
end

def ohai(title, *sput)
  title = Tty.truncate(title) if $stdout.tty? && !ARGV.verbose?
  puts "#{Tty.blue}==>#{Tty.white} #{title}#{Tty.reset}"
  puts sput
end

def oh1(title, options = {})
  if $stdout.tty? && !ARGV.verbose? && options.fetch(:truncate, :auto) == :auto
    title = Tty.truncate(title)
  end
  puts "#{Tty.green}==>#{Tty.white} #{title}#{Tty.reset}"
end

# Print a warning (do this rarely)
def opoo(warning)
  $stderr.puts "#{Tty.yellow}Warning#{Tty.reset}: #{warning}"
end

def onoe(error)
  $stderr.puts "#{Tty.red}Error#{Tty.reset}: #{error}"
end

def ofail(error)
  onoe error
  Homebrew.failed = true
end

def odie(error)
  onoe error
  exit 1
end

def odeprecated(method, replacement = nil, options = {})
  verb = if options[:die]
    "disabled"
  else
    "deprecated"
  end

  replacement_message = if replacement
    "Use #{replacement} instead."
  else
    "There is no replacement."
  end

  # Try to show the most relevant location in message, i.e. (if applicable):
  # - Location in a formula.
  # - Location outside of 'compat/'.
  # - Location of caller of deprecated method (if all else fails).
  backtrace = options.fetch(:caller, caller)
  tap_message = nil
  caller_message = backtrace.detect do |line|
    if line =~ %r{^#{Regexp.escape HOMEBREW_LIBRARY}/Taps/([^/]+/[^/]+)/}
      tap = Tap.fetch $1
      tap_message = "\nPlease report this to the #{tap} tap!"
      true
    end
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

  if ARGV.homebrew_developer? || options[:die] ||
     Homebrew.raise_deprecation_exceptions?
    raise FormulaMethodDeprecatedError, message
  else
    opoo "#{message}\n"
  end
end

def odisabled(method, replacement = nil, options = {})
  options = { :die => true, :caller => caller }.merge(options)
  odeprecated(method, replacement, options)
end

def pretty_installed(f)
  if !$stdout.tty?
    "#{f}"
  elsif Emoji.enabled?
    "#{Tty.highlight}#{f} #{Tty.green}#{Emoji.tick}#{Tty.reset}"
  else
    "#{Tty.highlight}#{Tty.green}#{f} (installed)#{Tty.reset}"
  end
end

def pretty_uninstalled(f)
  if !$stdout.tty?
    "#{f}"
  elsif Emoji.enabled?
    "#{f} #{Tty.red}#{Emoji.cross}#{Tty.reset}"
  else
    "#{Tty.red}#{f} (uninstalled)#{Tty.reset}"
  end
end

def pretty_duration(s)
  s = s.to_i
  res = ""

  if s > 59
    m = s / 60
    s %= 60
    res = "#{m} minute#{plural m}"
    return res if s == 0
    res << " "
  end

  res + "#{s} second#{plural s}"
end

def plural(n, s = "s")
  (n == 1) ? "" : s
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

  if $?.success?
    return
  elsif $?.exited?
    raise "Aborted due to non-zero exit status (#{$?.exitstatus})"
  else
    raise $?.inspect
  end
end

module Homebrew
  def self._system(cmd, *args)
    pid = fork do
      yield if block_given?
      args.collect!(&:to_s)
      exec(cmd, *args) rescue nil
      exit! 1 # never gets here unless exec failed
    end
    Process.wait(pid)
    $?.success?
  end

  def self.system(cmd, *args)
    puts "#{cmd} #{args*" "}" if ARGV.verbose?
    _system(cmd, *args)
  end

  def self.homebrew_version_string
    if pretty_revision = HOMEBREW_REPOSITORY.git_short_head
      last_commit = HOMEBREW_REPOSITORY.git_last_commit_date
      "#{HOMEBREW_VERSION} (git revision #{pretty_revision}; last commit #{last_commit})"
    else
      "#{HOMEBREW_VERSION} (no git repository)"
    end
  end

  def self.core_tap_version_string
    require "tap"
    tap = CoreTap.instance
    return "N/A" unless tap.installed?
    if pretty_revision = tap.git_short_head
      last_commit = tap.git_last_commit_date
      "(git revision #{pretty_revision}; last commit #{last_commit})"
    else
      "(no git repository)"
    end
  end

  def self.install_gem_setup_path!(name, version = nil, executable = name)
    require "rubygems"

    # Add Gem binary directory and (if missing) Ruby binary directory to PATH.
    path = ENV["PATH"].split(File::PATH_SEPARATOR)
    path.unshift(RUBY_BIN) if which("ruby") != RUBY_PATH
    path.unshift("#{Gem.user_dir}/bin")
    ENV["PATH"] = path.join(File::PATH_SEPARATOR)

    if Gem::Specification.find_all_by_name(name, version).empty?
      ohai "Installing or updating '#{name}' gem"
      install_args = %W[--no-ri --no-rdoc --user-install #{name}]
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
      odie "Failed to install/update the '#{name}' gem." if exit_code != 0
    end

    unless which executable
      odie <<-EOS.undent
        The '#{name}' gem is installed but couldn't find '#{executable}' in the PATH:
        #{ENV["PATH"]}
      EOS
    end
  end

  # Hash of Module => Set(method_names)
  @@injected_dump_stat_modules = {}

  def inject_dump_stats!(the_module, pattern)
    @@injected_dump_stat_modules[the_module] ||= []
    injected_methods = @@injected_dump_stat_modules[the_module]
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

    if $times.nil?
      $times = {}
      at_exit do
        col_width = [$times.keys.map(&:size).max + 2, 15].max
        $times.sort_by { |_k, v| v }.each do |method, time|
          puts format("%-*s %0.4f sec", col_width, "#{method}:", time)
        end
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

def with_custom_locale(locale)
  old_locale = ENV["LC_ALL"]
  ENV["LC_ALL"] = locale
  yield
ensure
  ENV["LC_ALL"] = old_locale
end

def run_as_not_developer(&_block)
  old = ENV.delete "HOMEBREW_DEVELOPER"
  yield
ensure
  ENV["HOMEBREW_DEVELOPER"] = old
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

def puts_columns(items)
  return if items.empty?

  unless $stdout.tty?
    puts items
    return
  end

  # TTY case: If possible, output using multiple columns.
  console_width = Tty.width
  console_width = 80 if console_width <= 0
  plain_item_lengths = items.map { |s| Tty.strip_ansi(s).length }
  max_len = plain_item_lengths.max
  col_gap = 2 # number of spaces between columns
  gap_str = " " * col_gap
  cols = (console_width + col_gap) / (max_len + col_gap)
  cols = 1 if cols < 1
  rows = (items.size + cols - 1) / cols
  cols = (items.size + rows - 1) / rows # avoid empty trailing columns

  if cols >= 2
    col_width = (console_width + col_gap) / cols - col_gap
    items = items.each_with_index.map do |item, index|
      item + "".ljust(col_width - plain_item_lengths[index])
    end
  end

  if cols == 1
    puts items
  else
    rows.times do |row_index|
      item_indices_for_row = row_index.step(items.size - 1, rows).to_a
      puts items.values_at(*item_indices_for_row).join(gap_str)
    end
  end
end

def which(cmd, path = ENV["PATH"])
  path.split(File::PATH_SEPARATOR).each do |p|
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
  path.split(File::PATH_SEPARATOR).map do |p|
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
  editor = ENV.values_at("HOMEBREW_EDITOR", "VISUAL", "EDITOR").compact.first
  return editor unless editor.nil?

  # Find Textmate
  editor = "mate" if which "mate"
  # Find BBEdit / TextWrangler
  editor ||= "edit" if which "edit"
  # Find vim
  editor ||= "vim" if which "vim"
  # Default to standard vim
  editor ||= "/usr/bin/vim"

  opoo <<-EOS.undent
    Using #{editor} because no editor was set in the environment.
    This may change in the future, so we recommend setting EDITOR, VISUAL,
    or HOMEBREW_EDITOR to your preferred text editor.
  EOS

  editor
end

def exec_editor(*args)
  puts "Editing #{args.join "\n"}"
  safe_exec(which_editor, *args)
end

def exec_browser(*args)
  browser = ENV["HOMEBREW_BROWSER"] || ENV["BROWSER"]
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
  @paths ||= ENV["PATH"].split(File::PATH_SEPARATOR).collect do |p|
    begin
      File.expand_path(p).chomp("/")
    rescue ArgumentError
      onoe "The following PATH component is invalid: #{p}"
    end
  end.uniq.compact
end

# return the shell profile file based on users' preference shell
def shell_profile
  case ENV["SHELL"]
  when %r{/(ba)?sh} then "~/.bash_profile"
  when %r{/zsh} then "~/.zshrc"
  when %r{/ksh} then "~/.kshrc"
  else "~/.bash_profile"
  end
end

def disk_usage_readable(size_in_bytes)
  if size_in_bytes >= 1_073_741_824
    size = size_in_bytes.to_f / 1_073_741_824
    unit = "G"
  elsif size_in_bytes >= 1_048_576
    size = size_in_bytes.to_f / 1_048_576
    unit = "M"
  elsif size_in_bytes >= 1_024
    size = size_in_bytes.to_f / 1_024
    unit = "K"
  else
    size = size_in_bytes
    unit = "B"
  end

  # avoid trailing zero after decimal point
  if (size * 10).to_i % 10 == 0
    "#{size.to_i}#{unit}"
  else
    "#{"%.1f" % size}#{unit}"
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
  if n_front_bytes == 0
    front = bytes[1..0]
    back = bytes[-max_bytes_in..-1]
  elsif n_back_bytes == 0
    front = bytes[0..(max_bytes_in - 1)]
    back = bytes[1..0]
  else
    front = bytes[0..(n_front_bytes - 1)]
    back = bytes[-n_back_bytes..-1]
  end
  out = front + glue_bytes + back
  out.force_encoding("UTF-8")
  out.encode!("UTF-16", :invalid => :replace)
  out.encode!("UTF-8")
  out
end

def link_path_manpages(path, command)
  return unless (path/"man").exist?
  conflicts = []
  (path/"man").find do |src|
    next if src.directory?
    dst = HOMEBREW_PREFIX/"share"/src.relative_path_from(path)
    next if dst.symlink? && src == dst.resolved_path
    if dst.exist?
      conflicts << dst
      next
    end
    dst.make_relative_symlink(src)
  end
  unless conflicts.empty?
    onoe <<-EOS.undent
      Could not link #{name} manpages to:
      #{conflicts.join("\n")}

      Please delete these files and run `#{command}`.
    EOS
  end
end
