require "optparse"
require "shellwords"

require "extend/optparse"

require "hbc/cli/base"
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

require "hbc/cli/internal_use_base"
require "hbc/cli/internal_audit_modified_casks"
require "hbc/cli/internal_appcast_checkpoint"
require "hbc/cli/internal_checkurl"
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
      # aliases from Homebrew that we don't (yet) support
      # 'ln'          => 'link',
      # 'configure'   => 'diy',
      # '--repo'      => '--repository',
      # 'environment' => '--env',
      # '-c1'         => '--config',
    }.freeze

    OPTIONS = {
      "--caskroom="             => :caskroom=,
      "--appdir="               => :appdir=,
      "--colorpickerdir="       => :colorpickerdir=,
      "--prefpanedir="          => :prefpanedir=,
      "--qlplugindir="          => :qlplugindir=,
      "--dictionarydir="        => :dictionarydir=,
      "--fontdir="              => :fontdir=,
      "--servicedir="           => :servicedir=,
      "--input_methoddir="      => :input_methoddir=,
      "--internet_plugindir="   => :internet_plugindir=,
      "--audio_unit_plugindir=" => :audio_unit_plugindir=,
      "--vst_plugindir="        => :vst_plugindir=,
      "--vst3_plugindir="       => :vst3_plugindir=,
      "--screen_saverdir="      => :screen_saverdir=,
    }.freeze

    FLAGS = {
      ["--[no-]binaries", :binaries] => true,
      ["--verbose",       :verbose]  => false,
      ["--outdated",      :outdated] => false,
      ["--help",          :help]     => false,
    }.freeze

    FLAGS.each do |(_, method), default_value|
      instance_variable_set(:"@#{method}", default_value)

      define_singleton_method(:"#{method}=") do |arg|
        instance_variable_set(:"@#{method}", arg)
      end

      define_singleton_method(:"#{method}?") do
        instance_variable_get(:"@#{method}")
      end
    end

    def self.command_classes
      @command_classes ||= constants.map(&method(:const_get))
                                    .select { |sym| sym.respond_to?(:run) }
                                    .sort_by(&:command_name)
    end

    def self.commands
      @commands ||= command_classes.map(&:command_name)
    end

    def self.lookup_command(command_string)
      @lookup ||= Hash[commands.zip(command_classes)]
      command_string = ALIASES.fetch(command_string, command_string)
      @lookup.fetch(command_string, command_string)
    end

    def self.should_init?(command)
      (command.is_a? Class) && (command < CLI::Base) && command.needs_init?
    end

    def self.run_command(command, *rest)
      if command.respond_to?(:run)
        # usual case: built-in command verb
        command.run(*rest)
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
          klass.run(*rest)
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
        NullCommand.new(command).run
      end
    end

    def self.process(arguments)
      unless ENV["MACOS_VERSION"].nil?
        MacOS.full_version = ENV["MACOS_VERSION"]
      end

      command_string, *rest = *arguments
      rest = process_options(rest)
      command = help? ? "help" : lookup_command(command_string)
      Hbc.default_tap.install unless Hbc.default_tap.installed?
      Hbc.init if should_init?(command)
      run_command(command, *rest)
    rescue CaskError, CaskSha256MismatchError, ArgumentError => e
      msg = e.message
      msg << e.backtrace.join("\n") if ARGV.debug?
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

    def self.parser
      # If you modify these arguments, please update USAGE.md
      @parser ||= OptionParser.new do |opts|
        opts.on("--language STRING") do
          # handled in OS::Mac
        end

        OPTIONS.each do |option, method|
          opts.on("#{option}" "PATH", Pathname) do |path|
            Hbc.public_send(method, path)
          end
        end

        opts.on("--binarydir=PATH") do
          opoo <<-EOS.undent
            Option --binarydir is obsolete!
            Homebrew-Cask now uses the same location as your Homebrew installation for executable links.
          EOS
        end

        FLAGS.keys.each do |flag, method|
          opts.on(flag) do |bool|
            send(:"#{method}=", bool)
          end
        end

        opts.on("--version") do
          raise OptionParser::InvalidOption # override default handling of --version
        end
      end
    end

    def self.process_options(args)
      all_args = Shellwords.shellsplit(ENV["HOMEBREW_CASK_OPTS"] || "") + args
      remaining = []
      until all_args.empty?
        begin
          head = all_args.shift
          remaining.concat(parser.parse([head]))
        rescue OptionParser::InvalidOption
          remaining << head
          retry
        rescue OptionParser::MissingArgument
          raise ArgumentError, "The option '#{head}' requires an argument."
        rescue OptionParser::AmbiguousOption
          raise ArgumentError, "There is more than one possible option that starts with '#{head}'."
        end
      end

      # for compat with Homebrew, not certain if this is desirable
      self.verbose = true if ARGV.verbose?

      remaining
    end

    class NullCommand
      def initialize(attempted_verb)
        @attempted_verb = attempted_verb
      end

      def run(*_args)
        purpose
        usage

        return if @attempted_verb.to_s.strip.empty?
        return if @attempted_verb == "help"

        raise ArgumentError, "Unknown command: #{@attempted_verb}"
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
