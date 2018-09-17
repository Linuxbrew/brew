require "version"

class PkgVersion
  include Comparable

  RX = /\A(.+?)(?:_(\d+))?\z/

  attr_reader :version, :revision

  def self.parse(path)
    _, version, revision = *path.match(RX)
    version = Version.create(version)
    new(version, revision.to_i)
  end

  def initialize(version, revision)
    @version = version
    @revision = revision
  end

  def head?
    version.head?
  end

  def to_s
    if revision.positive?
      "#{version}_#{revision}"
    else
      version.to_s
    end
  end
  alias to_str to_s

  def <=>(other)
    return unless other.is_a?(PkgVersion)

    (version <=> other.version).nonzero? || revision <=> other.revision
  end
  alias eql? ==

  def hash
    version.hash ^ revision.hash
  end
end
