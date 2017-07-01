class Checksum
  extend Forwardable

  attr_reader :hash_type, :hexdigest

  TYPES = [:sha256].freeze

  def initialize(hash_type, hexdigest)
    @hash_type = hash_type
    @hexdigest = hexdigest
  end

  delegate [:empty?, :to_s] => :@hexdigest

  def ==(other)
    hash_type == other.hash_type && hexdigest == other.hexdigest
  end
end
