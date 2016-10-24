#:  * `style` [`--fix`] [`--display-cop-names`] [<files>|<taps>|<formulae>]:
#:    Check formulae or files for conformance to Homebrew style guidelines.
#:
#:    <formulae> and <files> may not be combined. If both are omitted, style will run
#:    style checks on the whole Homebrew `Library`, including core code and all
#:    formulae.
#:
#:    If `--fix` is passed, style violations will be automatically fixed using
#:    RuboCop's `--auto-correct` feature.
#:
#:    If `--display-cop-names` is passed, the RuboCop cop name for each violation
#:    is included in the output.
#:
#:    Exits with a non-zero status if any style violations are found.

require "utils"
require "utils/json"

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

    Homebrew.failed = check_style_and_print(target, fix: ARGV.flag?("--fix"))
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
    Homebrew.install_gem_setup_path! "rubocop", "0.45.0"

    args = %w[
      --force-exclusion
    ]
    args << "--auto-correct" if fix

    if files.nil?
      args << "--config" << HOMEBREW_LIBRARY_PATH/".rubocop.yml"
      args += [HOMEBREW_LIBRARY_PATH]
    else
      args << "--config" << HOMEBREW_LIBRARY/".rubocop.yml"
      args += files
    end

    case output_type
    when :print
      args << "--display-cop-names" if ARGV.include? "--display-cop-names"
      args << "--format" << "simple" if files
      system "rubocop", *args
      !$?.success?
    when :json
      json = Utils.popen_read_text("rubocop", "--format", "json", *args)
      # exit status of 1 just means violations were found; other numbers mean execution errors
      # exitstatus can also be nil if RuboCop process crashes, e.g. due to
      # native extension problems
      raise "Error while running RuboCop" if $?.exitstatus.nil? || $?.exitstatus > 1
      RubocopResults.new(Utils::JSON.load(json))
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
