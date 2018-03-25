#:  * `style` [`--fix`] [`--display-cop-names`] [`--only-cops=`<cops>|`--except-cops=`<cops>] [<files>|<taps>|<formulae>]:
#:    Check formulae or files for conformance to Homebrew style guidelines.
#:
#:    Lists of <files>, <taps> and <formulae> may not be combined. If none are
#:    provided, `style` will run style checks on the whole Homebrew library,
#:    including core code and all formulae.
#:
#:    If `--fix` is passed, automatically fix style violations using RuboCop's
#:    auto-correct feature.
#:
#:    If `--display-cop-names` is passed, include the RuboCop cop name for each
#:    violation in the output.
#:
#:    If `--rspec` is passed, install and use the RuboCop RSpec gem.
#:
#:    Passing `--only-cops=`<cops> will check for violations of only the listed
#:    RuboCop <cops>, while `--except-cops=`<cops> will skip checking the listed
#:    <cops>. For either option <cops> should be a comma-separated list of cop names.
#:
#:    Exits with a non-zero status if any style violations are found.

require "utils"
require "json"
require "open3"

module Homebrew
  module_function

  def style
    target = if ARGV.named.empty?
      nil
    elsif ARGV.named.any? { |file| File.exist? file }
      ARGV.named
    elsif ARGV.named.any? { |tap| tap.count("/") == 1 }
      ARGV.named.map { |tap| Tap.fetch(tap).path }
    else
      ARGV.formulae.map(&:path)
    end

    only_cops = ARGV.value("only-cops").to_s.split(",")
    except_cops = ARGV.value("except-cops").to_s.split(",")
    if !only_cops.empty? && !except_cops.empty?
      odie "--only-cops and --except-cops cannot be used simultaneously!"
    end

    options = { fix: ARGV.flag?("--fix") }
    if !only_cops.empty?
      options[:only_cops] = only_cops
    elsif !except_cops.empty?
      options[:except_cops] = except_cops
    elsif only_cops.empty? && except_cops.empty?
      options[:except_cops] = %w[FormulaAudit
                                 FormulaAuditStrict
                                 NewFormulaAudit]
    end

    Homebrew.failed = check_style_and_print(target, options)
  end

  # Checks style for a list of files, printing simple RuboCop output.
  # Returns true if violations were found, false otherwise.
  def check_style_and_print(files, options = {})
    check_style_impl(files, :print, options)
  end

  # Checks style for a list of files, returning results as a RubocopResults
  # object parsed from its JSON output.
  def check_style_json(files, options = {})
    check_style_impl(files, :json, options)
  end

  def check_style_impl(files, output_type, options = {})
    fix = options[:fix]

    Homebrew.install_gem_setup_path! "rubocop", HOMEBREW_RUBOCOP_VERSION
    require "rubocop"
    require_relative "../rubocops"

    args = %w[
      --force-exclusion
    ]
    if fix
      args << "--auto-correct"
    else
      args << "--parallel"
    end

    if ARGV.include?("--rspec")
      Homebrew.install_gem! "rubocop-rspec"
      args += %w[--require rubocop-rspec]
    end

    if options[:except_cops]
      options[:except_cops].map! { |cop| RuboCop::Cop::Cop.registry.qualified_cop_name(cop.to_s, "") }
      cops_to_exclude = options[:except_cops].select do |cop|
        RuboCop::Cop::Cop.registry.names.include?(cop) ||
          RuboCop::Cop::Cop.registry.departments.include?(cop.to_sym)
      end

      args << "--except" << cops_to_exclude.join(",") unless cops_to_exclude.empty?
    elsif options[:only_cops]
      options[:only_cops].map! { |cop| RuboCop::Cop::Cop.registry.qualified_cop_name(cop.to_s, "") }
      cops_to_include = options[:only_cops].select do |cop|
        RuboCop::Cop::Cop.registry.names.include?(cop) ||
          RuboCop::Cop::Cop.registry.departments.include?(cop.to_sym)
      end

      if cops_to_include.empty?
        odie "RuboCops #{options[:only_cops].join(",")} were not found"
      end

      args << "--only" << cops_to_include.join(",")
    end

    if files.nil?
      args << "--config" << HOMEBREW_LIBRARY_PATH/".rubocop.yml"
      args << HOMEBREW_LIBRARY_PATH
    else
      args << "--config" << HOMEBREW_LIBRARY/".rubocop_audit.yml"
      args += files
    end

    cache_env = { "XDG_CACHE_HOME" => "#{HOMEBREW_CACHE}/style" }

    case output_type
    when :print
      args << "--debug" if ARGV.debug?
      args << "--display-cop-names" if ARGV.include? "--display-cop-names"
      args << "--format" << "simple" if files
      system(cache_env, "rubocop", "_#{HOMEBREW_RUBOCOP_VERSION}_", *args)
      !$CHILD_STATUS.success?
    when :json
      json, _, status = Open3.capture3(cache_env, "rubocop", "_#{HOMEBREW_RUBOCOP_VERSION}_", "--format", "json", *args)
      # exit status of 1 just means violations were found; other numbers mean
      # execution errors.
      # exitstatus can also be nil if RuboCop process crashes, e.g. due to
      # native extension problems.
      # JSON needs to be at least 2 characters.
      if !(0..1).cover?(status.exitstatus) || json.to_s.length < 2
        raise "Error running `rubocop --format json #{args.join " "}`"
      end
      RubocopResults.new(JSON.parse(json))
    else
      raise "Invalid output_type for check_style_impl: #{output_type}"
    end
  end

  class RubocopResults
    def initialize(json)
      @metadata = json["metadata"]
      @file_offenses = {}
      json["files"].each do |f|
        next if f["offenses"].empty?
        file = File.realpath(f["path"])
        @file_offenses[file] = f["offenses"].map { |x| RubocopOffense.new(x) }
      end
    end

    def file_offenses(path)
      @file_offenses[path.to_s]
    end
  end

  class RubocopOffense
    attr_reader :severity, :message, :corrected, :location, :cop_name

    def initialize(json)
      @severity = json["severity"]
      @message = json["message"]
      @cop_name = json["cop_name"]
      @corrected = json["corrected"]
      @location = RubocopLineLocation.new(json["location"])
    end

    def severity_code
      @severity[0].upcase
    end

    def to_s(options = {})
      if options[:display_cop_name]
        "#{severity_code}: #{location.to_short_s}: #{cop_name}: #{message}"
      else
        "#{severity_code}: #{location.to_short_s}: #{message}"
      end
    end
  end

  class RubocopLineLocation
    attr_reader :line, :column, :length

    def initialize(json)
      @line = json["line"]
      @column = json["column"]
      @length = json["length"]
    end

    def to_s
      "#{line}: col #{column} (#{length} chars)"
    end

    def to_short_s
      "#{line}: col #{column}"
    end
  end
end
