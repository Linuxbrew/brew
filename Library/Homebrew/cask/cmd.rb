require "optparse"
require "shellwords"

require "extend/optparse"

require "cask/config"

require "cask/cmd/options"

require "cask/cmd/abstract_command"
require "cask/cmd/audit"
require "cask/cmd/cat"
require "cask/cmd/create"
require "cask/cmd/doctor"
require "cask/cmd/edit"
require "cask/cmd/fetch"
require "cask/cmd/home"
require "cask/cmd/info"
require "cask/cmd/install"
require "cask/cmd/list"
require "cask/cmd/outdated"
require "cask/cmd/reinstall"
require "cask/cmd/style"
require "cask/cmd/uninstall"
require "cask/cmd/upgrade"
require "cask/cmd/zap"

require "cask/cmd/abstract_internal_command"
require "cask/cmd/internal_help"
require "cask/cmd/internal_stanza"

module Cask
  class Cmd
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

    option "--appdir=PATH",               ->(value) { Config.global.appdir               = value }
    option "--colorpickerdir=PATH",       ->(value) { Config.global.colorpickerdir       = value }
    option "--prefpanedir=PATH",          ->(value) { Config.global.prefpanedir          = value }
    option "--qlplugindir=PATH",          ->(value) { Config.global.qlplugindir          = value }
    option "--dictionarydir=PATH",        ->(value) { Config.global.dictionarydir        = value }
    option "--fontdir=PATH",              ->(value) { Config.global.fontdir              = value }
    option "--servicedir=PATH",           ->(value) { Config.global.servicedir           = value }
    option "--input_methoddir=PATH",      ->(value) { Config.global.input_methoddir      = value }
    option "--internet_plugindir=PATH",   ->(value) { Config.global.internet_plugindir   = value }
    option "--audio_unit_plugindir=PATH", ->(value) { Config.global.audio_unit_plugindir = value }
    option "--vst_plugindir=PATH",        ->(value) { Config.global.vst_plugindir        = value }
    option "--vst3_plugindir=PATH",       ->(value) { Config.global.vst3_plugindir       = value }
    option "--screen_saverdir=PATH",      ->(value) { Config.global.screen_saverdir      = value }

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

    def self.run_command(command, *args)
      return command.run(*args) if command.respond_to?(:run)

      tap_cmd_directories = Tap.cmd_directories

      path = PATH.new(tap_cmd_directories, ENV["HOMEBREW_PATH"])

      external_ruby_cmd = tap_cmd_directories.map { |d| d/"brewcask-#{command}.rb" }
                                             .find(&:file?)
      external_ruby_cmd ||= which("brewcask-#{command}.rb", path)

      if external_ruby_cmd
        require external_ruby_cmd

        klass = begin
          const_get(command.to_s.capitalize.to_sym)
        rescue NameError
          # External command is a stand-alone Ruby script.
          return
        end

        return klass.run(*args)
      end

      if external_command = which("brewcask-#{command}", path)
        exec external_command, *ARGV[1..-1]
      end

      NullCommand.new(command, *args).run
    end

    def self.run(*args)
      new(*args).run
    end

    def initialize(*args)
      @args = process_options(*args)
    end

    def detect_command_and_arguments(*args)
      command = args.find do |arg|
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
        args.unshift(command_name) unless command_name.nil?
        "help"
      else
        self.class.lookup_command(command_name)
      end

      MacOS.full_version = ENV["MACOS_VERSION"] unless ENV["MACOS_VERSION"].nil?

      Tap.default_cask_tap.install unless Tap.default_cask_tap.installed?
      self.class.run_command(command, *args)
    rescue CaskError, MethodDeprecatedError, ArgumentError, OptionParser::InvalidOption => e
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

        return if @command.nil?
        return if @command == "help" && @args.empty?

        raise ArgumentError, "help does not take arguments."
      end

      def purpose
        puts <<~EOS
          Homebrew Cask provides a friendly CLI workflow for the administration
          of macOS applications distributed as binaries.

        EOS
      end

      def usage
        max_command_len = Cmd.commands.map(&:length).max

        puts "Commands:\n\n"
        Cmd.command_classes.each do |klass|
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
