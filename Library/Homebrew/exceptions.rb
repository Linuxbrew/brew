class UsageError < RuntimeError
  attr_reader :reason

  def initialize(reason = nil)
    @reason = reason
  end

  def to_s
    s = "Invalid usage"
    s += ": #{reason}" if reason
    s
  end
end

class FormulaUnspecifiedError < UsageError
  def initialize
    super "This command requires a formula argument"
  end
end

class KegUnspecifiedError < UsageError
  def initialize
    super "This command requires a keg argument"
  end
end

class MultipleVersionsInstalledError < RuntimeError
  attr_reader :name

  def initialize(name)
    @name = name
    super "#{name} has multiple installed versions"
  end
end

class NotAKegError < RuntimeError; end

class NoSuchKegError < RuntimeError
  attr_reader :name

  def initialize(name)
    @name = name
    super "No such keg: #{HOMEBREW_CELLAR}/#{name}"
  end
end

class FormulaValidationError < StandardError
  attr_reader :attr, :formula

  def initialize(formula, attr, value)
    @attr = attr
    @formula = formula
    super "invalid attribute for formula '#{formula}': #{attr} (#{value.inspect})"
  end
end

class FormulaSpecificationError < StandardError; end

class MethodDeprecatedError < StandardError
  attr_accessor :issues_url
end

class FormulaUnavailableError < RuntimeError
  attr_reader :name
  attr_accessor :dependent

  def initialize(name)
    @name = name
  end

  def dependent_s
    "(dependency of #{dependent})" if dependent && dependent != name
  end

  def to_s
    "No available formula with the name \"#{name}\" #{dependent_s}"
  end
end

module FormulaClassUnavailableErrorModule
  attr_reader :path
  attr_reader :class_name
  attr_reader :class_list

  def to_s
    s = super
    s += "\nIn formula file: #{path}"
    s += "\nExpected to find class #{class_name}, but #{class_list_s}."
    s
  end

  private

  def class_list_s
    formula_class_list = class_list.select { |klass| klass < Formula }
    if class_list.empty?
      "found no classes"
    elsif formula_class_list.empty?
      "only found: #{format_list(class_list)} (not derived from Formula!)"
    else
      "only found: #{format_list(formula_class_list)}"
    end
  end

  def format_list(class_list)
    class_list.map { |klass| klass.name.split("::")[-1] }.join(", ")
  end
end

class FormulaClassUnavailableError < FormulaUnavailableError
  include FormulaClassUnavailableErrorModule

  def initialize(name, path, class_name, class_list)
    @path = path
    @class_name = class_name
    @class_list = class_list
    super name
  end
end

module FormulaUnreadableErrorModule
  attr_reader :formula_error

  def to_s
    "#{name}: " + formula_error.to_s
  end
end

class FormulaUnreadableError < FormulaUnavailableError
  include FormulaUnreadableErrorModule

  def initialize(name, error)
    super(name)
    @formula_error = error
  end
end

class TapFormulaUnavailableError < FormulaUnavailableError
  attr_reader :tap, :user, :repo

  def initialize(tap, name)
    @tap = tap
    @user = tap.user
    @repo = tap.repo
    super "#{tap}/#{name}"
  end

  def to_s
    s = super
    s += "\nPlease tap it and then try again: brew tap #{tap}" unless tap.installed?
    s
  end
end

class TapFormulaClassUnavailableError < TapFormulaUnavailableError
  include FormulaClassUnavailableErrorModule

  attr_reader :tap

  def initialize(tap, name, path, class_name, class_list)
    @path = path
    @class_name = class_name
    @class_list = class_list
    super tap, name
  end
end

class TapFormulaUnreadableError < TapFormulaUnavailableError
  include FormulaUnreadableErrorModule

  def initialize(tap, name, error)
    super(tap, name)
    @formula_error = error
  end
end

class TapFormulaAmbiguityError < RuntimeError
  attr_reader :name, :paths, :formulae

  def initialize(name, paths)
    @name = name
    @paths = paths
    @formulae = paths.map do |path|
      match = path.to_s.match(HOMEBREW_TAP_PATH_REGEX)
      "#{Tap.fetch(match[:user], match[:repo])}/#{path.basename(".rb")}"
    end

    super <<-EOS.undent
      Formulae found in multiple taps: #{formulae.map { |f| "\n       * #{f}" }.join}

      Please use the fully-qualified name e.g. #{formulae.first} to refer the formula.
    EOS
  end
end

class TapFormulaWithOldnameAmbiguityError < RuntimeError
  attr_reader :name, :possible_tap_newname_formulae, :taps

  def initialize(name, possible_tap_newname_formulae)
    @name = name
    @possible_tap_newname_formulae = possible_tap_newname_formulae

    @taps = possible_tap_newname_formulae.map do |newname|
      newname =~ HOMEBREW_TAP_FORMULA_REGEX
      "#{Regexp.last_match(1)}/#{Regexp.last_match(2)}"
    end

    super <<-EOS.undent
      Formulae with '#{name}' old name found in multiple taps: #{taps.map { |t| "\n       * #{t}" }.join}

      Please use the fully-qualified name e.g. #{taps.first}/#{name} to refer the formula or use its new name.
    EOS
  end
end

class TapUnavailableError < RuntimeError
  attr_reader :name

  def initialize(name)
    @name = name

    super <<-EOS.undent
      No available tap #{name}.
    EOS
  end
end

class TapRemoteMismatchError < RuntimeError
  attr_reader :name
  attr_reader :expected_remote
  attr_reader :actual_remote

  def initialize(name, expected_remote, actual_remote)
    @name = name
    @expected_remote = expected_remote
    @actual_remote = actual_remote

    super <<-EOS.undent
      Tap #{name} remote mismatch.
      #{expected_remote} != #{actual_remote}
    EOS
  end
end

class TapAlreadyTappedError < RuntimeError
  attr_reader :name

  def initialize(name)
    @name = name

    super <<-EOS.undent
      Tap #{name} already tapped.
    EOS
  end
end

class TapAlreadyUnshallowError < RuntimeError
  attr_reader :name

  def initialize(name)
    @name = name

    super <<-EOS.undent
      Tap #{name} already a full clone.
    EOS
  end
end

class TapPinStatusError < RuntimeError
  attr_reader :name, :pinned

  def initialize(name, pinned)
    @name = name
    @pinned = pinned

    super pinned ? "#{name} is already pinned." : "#{name} is already unpinned."
  end
end

class OperationInProgressError < RuntimeError
  def initialize(name)
    message = <<-EOS.undent
      Operation already in progress for #{name}
      Another active Homebrew process is already using #{name}.
      Please wait for it to finish or terminate it to continue.
      EOS

    super message
  end
end

class CannotInstallFormulaError < RuntimeError; end

class FormulaInstallationAlreadyAttemptedError < RuntimeError
  def initialize(formula)
    super "Formula installation already attempted: #{formula.full_name}"
  end
end

class UnsatisfiedRequirements < RuntimeError
  def initialize(reqs)
    if reqs.length == 1
      super "An unsatisfied requirement failed this build."
    else
      super "Unsatisfied requirements failed this build."
    end
  end
end

class FormulaConflictError < RuntimeError
  attr_reader :formula, :conflicts

  def initialize(formula, conflicts)
    @formula = formula
    @conflicts = conflicts
    super message
  end

  def conflict_message(conflict)
    message = []
    message << "  #{conflict.name}"
    message << ": because #{conflict.reason}" if conflict.reason
    message.join
  end

  def message
    message = []
    message << "Cannot install #{formula.full_name} because conflicting formulae are installed."
    message.concat conflicts.map { |c| conflict_message(c) } << ""
    message << <<-EOS.undent
      Please `brew unlink #{conflicts.map(&:name) * " "}` before continuing.

      Unlinking removes a formula's symlinks from #{HOMEBREW_PREFIX}. You can
      link the formula again after the install finishes. You can --force this
      install, but the build may fail or cause obscure side-effects in the
      resulting software.
      EOS
    message.join("\n")
  end
end

class FormulaAmbiguousPythonError < RuntimeError
  def initialize(formula)
    super <<-EOS.undent
      The version of python to use with the virtualenv in the `#{formula.full_name}` formula
      cannot be guessed automatically. If the simultaneous use of python and python3
      is intentional, please add `:using => "python"` or `:using => "python3"` to
      `virtualenv_install_with_resources` to resolve the ambiguity manually.
    EOS
  end
end

class BuildError < RuntimeError
  attr_reader :formula, :env
  attr_accessor :options

  def initialize(formula, cmd, args, env)
    @formula = formula
    @env = env
    args = args.map { |arg| arg.to_s.gsub " ", "\\ " }.join(" ")
    super "Failed executing: #{cmd} #{args}"
  end

  def issues
    @issues ||= fetch_issues
  end

  def fetch_issues
    GitHub.issues_for_formula(formula.name, tap: formula.tap)
  rescue GitHub::RateLimitExceededError => e
    opoo e.message
    []
  end

  def dump
    puts

    if ARGV.verbose?
      require "system_config"
      require "build_environment"

      ohai "Formula"
      puts "Tap: #{formula.tap}" if formula.tap?
      puts "Path: #{formula.path}"
      ohai "Configuration"
      SystemConfig.dump_verbose_config
      ohai "ENV"
      Homebrew.dump_build_env(env)
      puts
      onoe "#{formula.full_name} #{formula.version} did not build"
      unless (logs = Dir["#{formula.logs}/*"]).empty?
        puts "Logs:"
        puts logs.map { |fn| "     #{fn}" }.join("\n")
      end
    end

    if formula.tap && defined?(OS::ISSUES_URL)
      if formula.tap.official?
        puts Formatter.error(Formatter.url(OS::ISSUES_URL), label: "READ THIS")
      elsif issues_url = formula.tap.issues_url
        puts <<-EOS.undent
          If reporting this issue please do so at (not Homebrew/brew or Homebrew/core):
          #{Formatter.url(issues_url)}
        EOS
      else
        puts <<-EOS.undent
          If reporting this issue please do so to (not Homebrew/brew or Homebrew/core):
          #{formula.tap}
        EOS
      end
    else
      puts <<-EOS.undent
        Do not report this issue to Homebrew/brew or Homebrew/core!
      EOS
    end

    puts

    if issues && !issues.empty?
      puts "These open issues may also help:"
      puts issues.map { |i| "#{i["title"]} #{i["html_url"]}" }.join("\n")
    end

    require "diagnostic"
    checks = Homebrew::Diagnostic::Checks.new
    checks.build_error_checks.each do |check|
      out = checks.send(check)
      next if out.nil?
      puts
      ofail out
    end
  end
end

# raised by FormulaInstaller.check_dependencies_bottled and
# FormulaInstaller.install if the formula or its dependencies are not bottled
# and are being installed on a system without necessary build tools
class BuildToolsError < RuntimeError
  def initialize(formulae)
    if formulae.length > 1
      formula_text = "formulae"
      package_text = "binary packages"
    else
      formula_text = "formula"
      package_text = "a binary package"
    end

    super <<-EOS.undent
      The following #{formula_text}:
        #{formulae.join(", ")}
      cannot be installed as #{package_text} and must be built from source.
      #{DevelopmentTools.installation_instructions}
    EOS
  end
end

# raised by Homebrew.install, Homebrew.reinstall, and Homebrew.upgrade
# if the user passes any flags/environment that would case a bottle-only
# installation on a system without build tools to fail
class BuildFlagsError < RuntimeError
  def initialize(flags)
    if flags.length > 1
      flag_text = "flags"
      require_text = "require"
    else
      flag_text = "flag"
      require_text = "requires"
    end

    super <<-EOS.undent
      The following #{flag_text}:
        #{flags.join(", ")}
      #{require_text} building tools, but none are installed.
      #{DevelopmentTools.installation_instructions}
      Alternatively, remove the #{flag_text} to attempt bottle installation.
    EOS
  end
end

# raised by CompilerSelector if the formula fails with all of
# the compilers available on the user's system
class CompilerSelectionError < RuntimeError
  def initialize(formula)
    super <<-EOS.undent
      #{formula.full_name} cannot be built with any available compilers.
      #{DevelopmentTools.custom_installation_instructions}
    EOS
  end
end

# Raised in Resource.fetch
class DownloadError < RuntimeError
  def initialize(resource, cause)
    super <<-EOS.undent
      Failed to download resource #{resource.download_name.inspect}
      #{cause.message}
      EOS
    set_backtrace(cause.backtrace)
  end
end

# raised in CurlDownloadStrategy.fetch
class CurlDownloadStrategyError < RuntimeError
  def initialize(url)
    case url
    when %r{^file://(.+)}
      super "File does not exist: #{Regexp.last_match(1)}"
    else
      super "Download failed: #{url}"
    end
  end
end

# raised by safe_system in utils.rb
class ErrorDuringExecution < RuntimeError
  def initialize(cmd, args = [])
    args = args.map { |a| a.to_s.gsub " ", "\\ " }.join(" ")
    super "Failure while executing: #{cmd} #{args}"
  end
end

# raised by Pathname#verify_checksum when "expected" is nil or empty
class ChecksumMissingError < ArgumentError; end

# raised by Pathname#verify_checksum when verification fails
class ChecksumMismatchError < RuntimeError
  attr_reader :expected, :hash_type

  def initialize(fn, expected, actual)
    @expected = expected
    @hash_type = expected.hash_type.to_s.upcase

    super <<-EOS.undent
      #{@hash_type} mismatch
      Expected: #{expected}
      Actual: #{actual}
      Archive: #{fn}
      To retry an incomplete download, remove the file above.
      EOS
  end
end

class ResourceMissingError < ArgumentError
  def initialize(formula, resource)
    super "#{formula.full_name} does not define resource #{resource.inspect}"
  end
end

class DuplicateResourceError < ArgumentError
  def initialize(resource)
    super "Resource #{resource.inspect} is defined more than once"
  end
end

# raised when a single patch file is not found and apply hasn't been specified
class MissingApplyError < RuntimeError; end

class BottleVersionMismatchError < RuntimeError
  def initialize(bottle_file, bottle_version, formula, formula_version)
    super <<-EOS.undent
      Bottle version mismatch
      Bottle: #{bottle_file} (#{bottle_version})
      Formula: #{formula.full_name} (#{formula_version})
    EOS
  end
end
