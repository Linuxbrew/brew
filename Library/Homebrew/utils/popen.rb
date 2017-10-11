module Utils
  def self.popen_read(*args, **options, &block)
    popen(args, "rb", options, &block)
  end

  def self.popen_write(*args, **options, &block)
    popen(args, "wb", options, &block)
  end

  def self.popen(args, mode, options = {})
    IO.popen("-", mode) do |pipe|
      if pipe
        return pipe.read unless block_given?
        yield pipe
      else
        options[:err] ||= :close unless ENV["HOMEBREW_STDERR"]
        exec(*args, options)
      end
    end
  end
end
