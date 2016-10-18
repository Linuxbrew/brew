class Checksum
  attr_reader :hash_type, :hexdigest
  alias to_s hexdigest

  TYPES = [:sha256].freeze

  def initialize(hash_type, hexdigest)
    @hash_type = hash_type
    @hexdigest = hexdigest
  end

  def empty?
    hexdigest.empty?
  end

  def ==(other)
    hash_type == other.hash_type && hexdigest == other.hexdigest
  end
end
