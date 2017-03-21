require "open3"
require "shellwords"

require "extend/io"

require "hbc/utils/hash_validator"

module Hbc
  class SystemCommand
    attr_reader :command

    def self.run(executable, options = {})
      new(executable, options).run!
    end

    def self.run!(command, options = {})
      run(command, options.merge(must_succeed: true))
    end

    def run!
      @processed_output = { stdout: "", stderr: "" }
      odebug "Executing: #{expanded_command.utf8_inspect}"

      each_output_line do |type, line|
        case type
        when :stdout
          processed_output[:stdout] << line
          ohai line.chomp if options[:print_stdout]
        when :stderr
          processed_output[:stderr] << line
          ohai line.chomp if options[:print_stderr]
        end
      end

      assert_success if options[:must_succeed]
      result
    end

    def initialize(executable, options)
      @executable = executable
      @options = options
      process_options!
    end

    private

    attr_reader :executable, :options, :processed_output, :processed_status

    def process_options!
      options.extend(HashValidator)
             .assert_valid_keys :input, :print_stdout, :print_stderr, :args, :must_succeed, :sudo
      sudo_prefix = %w[/usr/bin/sudo -E --]
      sudo_prefix = sudo_prefix.insert(1, "-A") unless ENV["SUDO_ASKPASS"].nil?
      @command = [executable]
      options[:print_stderr] = true    unless options.key?(:print_stderr)
      @command.unshift(*sudo_prefix)   if  options[:sudo]
      @command.concat(options[:args])  if  options.key?(:args) && !options[:args].empty?
      @command[0] = Shellwords.shellescape(@command[0]) if @command.size == 1
      nil
    end

    def assert_success
      return if processed_status && processed_status.success?
      raise CaskCommandFailedError.new(command.utf8_inspect, processed_output[:stdout], processed_output[:stderr], processed_status)
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
      raw_stdin, raw_stdout, raw_stderr, raw_wait_thr =
        Open3.popen3(*expanded_command)

      write_input_to(raw_stdin) if options[:input]
      raw_stdin.close_write
      each_line_from [raw_stdout, raw_stderr], &b

      @processed_status = raw_wait_thr.value
    end

    def write_input_to(raw_stdin)
      Array(options[:input]).each { |line| raw_stdin.puts line }
    end

    def each_line_from(sources)
      loop do
        readable_sources = IO.select(sources)[0]
        readable_sources.delete_if(&:eof?).first(1).each do |source|
          type = (source == sources[0] ? :stdout : :stderr)
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
  end
end

module Hbc
  class SystemCommand
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
        _warn_plist_garbage(command, Regexp.last_match[1]) if Hbc.debug
        output.sub!(%r{(<\s*/\s*plist\s*>)(.*?)\Z}m, '\1')
        _warn_plist_garbage(command, Regexp.last_match[2])
        xml = Plist.parse_xml(output)
        unless xml.respond_to?(:keys) && !xml.keys.empty?
          raise CaskError, <<-EOS
    Empty result parsing plist output from command.
      command was:
      #{command.utf8_inspect}
      output we attempted to parse:
      #{output}
          EOS
        end
        xml
      rescue Plist::ParseError => e
        raise CaskError, <<-EOS
    Error parsing plist output from command.
      command was:
      #{command.utf8_inspect}
      error was:
      #{e}
      output we attempted to parse:
      #{output}
        EOS
      end
    end
  end
end
