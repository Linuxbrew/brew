require "optparse"
require "shellwords"

require "extend/optparse"
require "hbc/cli/options"

require "hbc/cli/abstract_command"
require "hbc/cli/audit"
require "hbc/cli/cat"
require "hbc/cli/cleanup"
require "hbc/cli/create"
require "hbc/cli/doctor"
require "hbc/cli/edit"
require "hbc/cli/fetch"
require "hbc/cli/home"
require "hbc/cli/info"
require "hbc/cli/install"
require "hbc/cli/list"
require "hbc/cli/outdated"
require "hbc/cli/reinstall"
require "hbc/cli/search"
require "hbc/cli/style"
require "hbc/cli/uninstall"
require "hbc/cli/--version"
require "hbc/cli/zap"

require "hbc/cli/abstract_internal_command"
require "hbc/cli/internal_audit_modified_casks"
require "hbc/cli/internal_appcast_checkpoint"
require "hbc/cli/internal_dump"
require "hbc/cli/internal_help"
require "hbc/cli/internal_stanza"

module Hbc
  class CLI
    ALIASES = {
      "ls"       => "list",
      "homepage" => "home",
      "-S"       => "search",    # verb starting with "-" is questionable
      "up"       => "update",
      "instal"   => "install",   # gem does the same
      "uninstal" => "uninstall",
      "rm"       => "uninstall",
      "remove"   => "uninstall",
      "abv"      => "info",
      "dr"       => "doctor",
    }.freeze

    include Options

    option "--appdir=PATH",               ->(value) { Hbc.appdir               = value }
    option "--colorpickerdir=PATH",       ->(value) { Hbc.colorpickerdir       = value }
    option "--prefpanedir=PATH",          ->(value) { Hbc.prefpanedir          = value }
    option "--qlplugindir=PATH",          ->(value) { Hbc.qlplugindir          = value }
    option "--dictionarydir=PATH",        ->(value) { Hbc.dictionarydir        = value }
    option "--fontdir=PATH",              ->(value) { Hbc.fontdir              = value }
    option "--servicedir=PATH",           ->(value) { Hbc.servicedir           = value }
    option "--input_methoddir=PATH",      ->(value) { Hbc.input_methoddir      = value }
    option "--internet_plugindir=PATH",   ->(value) { Hbc.internet_plugindir   = value }
    option "--audio_unit_plugindir=PATH", ->(value) { Hbc.audio_unit_plugindir = value }
    option "--vst_plugindir=PATH",        ->(value) { Hbc.vst_plugindir        = value }
    option "--vst3_plugindir=PATH",       ->(value) { Hbc.vst3_plugindir       = value }
    option "--screen_saverdir=PATH",      ->(value) { Hbc.screen_saverdir      = value }

    option "--help", :help, false

    # handled in OS::Mac
    option "--language a,b,c", ->(*) {}

    # override default handling of --version
    option "--version", ->(*) { raise OptionParser::InvalidOption }

    def self.command_classes
      @command_classes ||= constants.map(&method(:const_get))
                                    .select { |klass| klass.respond_to?(:run) }
                                    .reject(&:abstract?)
                                    .sort_by(&:command_name)
    end

    def self.commands
      @commands ||= command_classes.map(&:command_name)
    end

    def self.lookup_command(command_name)
      @lookup ||= Hash[commands.zip(command_classes)]
      command_name = ALIASES.fetch(command_name, command_name)
      @lookup.fetch(command_name, command_name)
    end

    def self.should_init?(command)
      command.is_a?(Class) && !command.abstract? && command.needs_init?
    end

    def self.run_command(command, *args)
      if command.respond_to?(:run)
        # usual case: built-in command verb
        command.run(*args)
      elsif require?(which("brewcask-#{command}.rb"))
        # external command as Ruby library on PATH, Homebrew-style
      elsif command.to_s.include?("/") && require?(command.to_s)
        # external command as Ruby library with literal path, useful
        # for development and troubleshooting
        sym = File.basename(command.to_s, ".rb").capitalize
        klass = begin
                  const_get(sym)
                rescue NameError
                  nil
                end

        if klass.respond_to?(:run)
          # invoke "run" on a Ruby library which follows our coding conventions
          # other Ruby libraries must do everything via "require"
          klass.run(*args)
        end
      elsif which("brewcask-#{command}")
        # arbitrary external executable on PATH, Homebrew-style
        exec "brewcask-#{command}", *ARGV[1..-1]
      elsif Pathname.new(command.to_s).executable? &&
            command.to_s.include?("/") &&
            !command.to_s.match(/\.rb$/)
        # arbitrary external executable with literal path, useful
        # for development and troubleshooting
        exec command, *ARGV[1..-1]
      else
        # failure
        NullCommand.new(command, *args).run
      end
    end

    def self.run(*args)
      new(*args).run
    end

    def initialize(*args)
      @args = process_options(*args)
    end

    def detect_command_and_arguments(*args)
      command = args.detect do |arg|
        if self.class.commands.include?(arg)
          true
        else
          break unless arg.start_with?("-")
        end
      end

      if index = args.index(command)
        args.delete_at(index)
      end

      [*command, *args]
    end

    def run
      command_name, *args = detect_command_and_arguments(*@args)
      command = if help?
        args.unshift(command_name)
        "help"
      else
        self.class.lookup_command(command_name)
      end

      MacOS.full_version = ENV["MACOS_VERSION"] unless ENV["MACOS_VERSION"].nil?

      Hbc.default_tap.install unless Hbc.default_tap.installed?
      Hbc.init if self.class.should_init?(command)
      self.class.run_command(command, *args)
    rescue CaskError, ArgumentError, OptionParser::InvalidOption => e
      msg = e.message
      msg << e.backtrace.join("\n").prepend("\n") if ARGV.debug?
      onoe msg
      exit 1
    rescue StandardError, ScriptError, NoMemoryError => e
      msg = "#{e.message}\n"
      msg << Utils.error_message_with_suggestions
      msg << e.backtrace.join("\n")
      onoe msg
      exit 1
    end

    def self.nice_listing(cask_list)
      cask_taps = {}
      cask_list.each do |c|
        user, repo, token = c.split "/"
        repo.sub!(/^homebrew-/i, "")
        cask_taps[token] ||= []
        cask_taps[token].push "#{user}/#{repo}"
      end
      list = []
      cask_taps.each do |token, taps|
        if taps.length == 1
          list.push token
        else
          taps.each { |r| list.push [r, token].join "/" }
        end
      end
      list.sort
    end

    def process_options(*args)
      all_args = Shellwords.shellsplit(ENV["HOMEBREW_CASK_OPTS"] || "") + args

      non_options = []

      if idx = all_args.index("--")
        non_options += all_args.drop(idx)
        all_args = all_args.first(idx)
      end

      remaining = all_args.select do |arg|
        begin
          !process_arguments([arg]).empty?
        rescue OptionParser::InvalidOption, OptionParser::MissingArgument, OptionParser::AmbiguousOption
          true
        end
      end

      remaining + non_options
    end

    class NullCommand
      def initialize(command, *args)
        @command = command
        @args = args
      end

      def run(*_args)
        purpose
        usage

        return if @command == "help" && @args.empty?

        unknown_command = @args.empty? ? @command : @args.first
        raise ArgumentError, "Unknown command: #{unknown_command}"
      end

      def purpose
        puts <<-EOS.undent
          brew-cask provides a friendly homebrew-style CLI workflow for the
          administration of macOS applications distributed as binaries.

        EOS
      end

      def usage
        max_command_len = CLI.commands.map(&:length).max

        puts "Commands:\n\n"
        CLI.command_classes.each do |klass|
          next unless klass.visible
          puts "    #{klass.command_name.ljust(max_command_len)}  #{_help_for(klass)}"
        end
        puts %Q(\nSee also "man brew-cask")
      end

      def help
        ""
      end

      def _help_for(klass)
        klass.respond_to?(:help) ? klass.help : nil
      end
    end
  end
end
