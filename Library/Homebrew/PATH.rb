class PATH
  include Enumerable
  extend Forwardable

  def_delegator :@paths, :each

  def initialize(*paths)
    @paths = parse(*paths)
  end

  def prepend(*paths)
    @paths = parse(*paths, *@paths)
    self
  end

  def append(*paths)
    @paths = parse(*@paths, *paths)
    self
  end

  def insert(index, *paths)
    @paths = parse(*@paths.insert(index, *paths))
    self
  end

  def select(&block)
    self.class.new(@paths.select(&block))
  end

  def reject(&block)
    self.class.new(@paths.reject(&block))
  end

  def to_ary
    @paths.dup.to_ary
  end
  alias to_a to_ary

  def to_str
    @paths.join(File::PATH_SEPARATOR)
  end
  alias to_s to_str

  def ==(other)
    if other.respond_to?(:to_ary)
      return true if to_ary == other.to_ary
    end

    if other.respond_to?(:to_str)
      return true if to_str == other.to_str
    end

    false
  end

  def empty?
    @paths.empty?
  end

  def existing
    existing_path = select(&File.method(:directory?))
    # return nil instead of empty PATH, to unset environment variables
    existing_path unless existing_path.empty?
  end

  private

  def parse(*paths)
    paths.flatten
         .compact
         .flat_map { |p| Pathname.new(p).to_path.split(File::PATH_SEPARATOR) }
         .uniq
  end
end
