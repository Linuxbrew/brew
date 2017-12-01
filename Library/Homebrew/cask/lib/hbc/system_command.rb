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
          processed_output[:stdout] << line
          ohai line.chomp if print_stdout?
        when :stderr
          processed_output[:stderr] << line
          ohai line.chomp if print_stderr?
        end
      end

      assert_success if must_succeed?
      result
    end

    def initialize(executable, args: [], sudo: false, input: [], print_stdout: false, print_stderr: true, must_succeed: false, **options)
      @executable = executable
      @args = args
      @sudo = sudo
      @input = input
      @print_stdout = print_stdout
      @print_stderr = print_stderr
      @must_succeed = must_succeed
      options.extend(HashValidator).assert_valid_keys(:chdir)
      @options = options
    end

    def command
      [*sudo_prefix, executable, *args]
    end

    private

    attr_reader :executable, :args, :input, :options, :processed_output, :processed_status

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

      unless File.exist?(executable)
        executable = which(executable, PATH.new(ENV["PATH"], HOMEBREW_PREFIX/"bin"))
      end

      raw_stdin, raw_stdout, raw_stderr, raw_wait_thr =
        Open3.popen3([executable, executable], *args, **options)

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
        readable_sources = IO.select(sources)[0]
        readable_sources.delete_if(&:eof?).first(1).each do |source|
          type = ((source == sources[0]) ? :stdout : :stderr)
          begin
            yield(type, source.readline_nonblock || "")
          rescue IO::WaitReadable, EOFError
            next
          end
        end
        break if readable_sources.empty?
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

      def plist
        @plist ||= self.class._parse_plist(@command, @stdout.dup)
      end

      def success?
        @exit_status.zero?
      end

      def merged_output
        @merged_output ||= @stdout + @stderr
      end

      def to_s
        @stdout
      end

      def self._warn_plist_garbage(command, garbage)
        return true unless garbage =~ /\S/
        external = File.basename(command.first)
        lines = garbage.strip.split("\n")
        opoo "Non-XML stdout from #{external}:"
        $stderr.puts lines.map { |l| "    #{l}" }
      end

      def self._parse_plist(command, output)
        raise CaskError, "Empty plist input" unless output =~ /\S/
        output.sub!(/\A(.*?)(<\?\s*xml)/m, '\2')
        _warn_plist_garbage(command, Regexp.last_match[1]) if ARGV.debug?
        output.sub!(%r{(<\s*/\s*plist\s*>)(.*?)\Z}m, '\1')
        _warn_plist_garbage(command, Regexp.last_match[2])
        xml = Plist.parse_xml(output)
        unless xml.respond_to?(:keys) && !xml.keys.empty?
          raise CaskError, <<~EOS
            Empty result parsing plist output from command.
              command was:
              #{command}
              output we attempted to parse:
              #{output}
          EOS
        end
        xml
      end
    end
  end
end
