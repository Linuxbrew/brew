module Utils
  def self.popen_read(*args, **options, &block)
    popen(args, "rb", options, &block)
  end

  def self.safe_popen_read(*args, **options, &block)
    output = popen_read(*args, **options, &block)
    return output if $CHILD_STATUS.success?

    raise ErrorDuringExecution.new(args, status: $CHILD_STATUS, output: [[:stdout, output]])
  end

  def self.popen_write(*args, **options, &block)
    popen(args, "wb", options, &block)
  end

  def self.safe_popen_write(*args, **options, &block)
    output = popen_write(*args, **options, &block)
    return output if $CHILD_STATUS.success?

    raise ErrorDuringExecution.new(args, status: $CHILD_STATUS, output: [[:stdout, output]])
  end

  def self.popen(args, mode, options = {})
    IO.popen("-", mode) do |pipe|
      if pipe
        return pipe.read unless block_given?

        yield pipe
      else
        options[:err] ||= :close unless ENV["HOMEBREW_STDERR"]
        begin
          exec(*args, options)
        rescue Errno::ENOENT
          $stderr.puts "brew: command not found: #{args[0]}" unless options[:err] == :close
          exit! 127
        rescue SystemCallError
          $stderr.puts "brew: exec failed: #{args[0]}" unless options[:err] == :close
          exit! 1
        end
      end
    end
  end
end
