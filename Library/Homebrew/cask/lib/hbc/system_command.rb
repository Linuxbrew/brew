require "open3"
require "vendor/plist/plist"
require "shellwords"

require "extend/io"

require "hbc/utils/hash_validator"

module Hbc
  class SystemCommand
    extend Predicable

    def self.run(executable, **options)
      new(executable, **options).run!
    end

    def self.run!(command, **options)
      run(command, **options, must_succeed: true)
    end

    def run!
      @processed_output = { stdout: "", stderr: "" }
      odebug "Executing: #{expanded_command}"

      each_output_line do |type, line|
        case type
        when :stdout
          puts line.chomp if print_stdout?
          processed_output[:stdout] << line
        when :stderr
          $stderr.puts Formatter.error(line.chomp) if print_stderr?
          processed_output[:stderr] << line
        end
      end

      assert_success if must_succeed?
      result
    end

    def initialize(executable, args: [], sudo: false, input: [], print_stdout: false, print_stderr: true, must_succeed: false, path: ENV["PATH"], **options)
      @executable = executable
      @args = args
      @sudo = sudo
      @input = input
      @print_stdout = print_stdout
      @print_stderr = print_stderr
      @must_succeed = must_succeed
      options.extend(HashValidator).assert_valid_keys(:chdir)
      @options = options
      @path = path
    end

    def command
      [*sudo_prefix, executable, *args]
    end

    private

    attr_reader :executable, :args, :input, :options, :processed_output, :processed_status, :path

    attr_predicate :sudo?, :print_stdout?, :print_stderr?, :must_succeed?

    def sudo_prefix
      return [] unless sudo?
      askpass_flags = ENV.key?("SUDO_ASKPASS") ? ["-A"] : []
      ["/usr/bin/sudo", *askpass_flags, "-E", "--"]
    end

    def assert_success
      return if processed_status&.success?
      raise CaskCommandFailedError.new(command, processed_output[:stdout], processed_output[:stderr], processed_status)
    end

    def expanded_command
      @expanded_command ||= command.map do |arg|
        if arg.respond_to?(:to_path)
          File.absolute_path(arg)
        else
          String(arg)
        end
      end
    end

    def each_output_line(&b)
      executable, *args = expanded_command

      raw_stdin, raw_stdout, raw_stderr, raw_wait_thr =
        Open3.popen3({ "PATH" => path }, [executable, executable], *args, **options)

      write_input_to(raw_stdin)
      raw_stdin.close_write
      each_line_from [raw_stdout, raw_stderr], &b

      @processed_status = raw_wait_thr.value
    end

    def write_input_to(raw_stdin)
      [*input].each(&raw_stdin.method(:print))
    end

    def each_line_from(sources)
      loop do
        readable_sources, = IO.select(sources)

        readable_sources = readable_sources.reject(&:eof?)

        break if readable_sources.empty?

        readable_sources.each do |source|
          begin
            line = source.readline_nonblock || ""
            type = (source == sources[0]) ? :stdout : :stderr
            yield(type, line)
          rescue IO::WaitReadable, EOFError
            next
          end
        end
      end

      sources.each(&:close_read)
    end

    def result
      Result.new(command,
                 processed_output[:stdout],
                 processed_output[:stderr],
                 processed_status.exitstatus)
    end

    class Result
      attr_accessor :command, :stdout, :stderr, :exit_status

      def initialize(command, stdout, stderr, exit_status)
        @command     = command
        @stdout      = stdout
        @stderr      = stderr
        @exit_status = exit_status
      end

      def success?
        @exit_status.zero?
      end

      def plist
        @plist ||= begin
          output = stdout

          if /\A(?<garbage>.*?)<\?\s*xml/m =~ output
            output = output.sub(/\A#{Regexp.escape(garbage)}/m, "")
            warn_plist_garbage(garbage)
          end

          if %r{<\s*/\s*plist\s*>(?<garbage>.*?)\Z}m =~ output
            output = output.sub(/#{Regexp.escape(garbage)}\Z/, "")
            warn_plist_garbage(garbage)
          end

          Plist.parse_xml(output)
        end
      end

      def warn_plist_garbage(garbage)
        return unless ARGV.verbose?
        return unless garbage =~ /\S/
        opoo "Received non-XML output from #{Formatter.identifier(command.first)}:"
        $stderr.puts garbage.strip
      end
      private :warn_plist_garbage
    end
  end
end
