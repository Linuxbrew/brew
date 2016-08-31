class Formula
  def self.sha1(val)
    odeprecated "Formula.sha1", "Formula.sha256"
    stable.sha1(val)
  end
end

class SoftwareSpec
  def sha1(val)
    odeprecated "SoftwareSpec#sha1", "SoftwareSpec#sha256"
    @resource.sha1(val)
  end
end

class Resource
  def sha1(val)
    odeprecated "Resource#sha1", "Resource#sha256"
    @checksum = Checksum.new(:sha1, val)
  end
end

class BottleSpecification
  def sha1(val)
    odeprecated "BottleSpecification#sha1", "BottleSpecification#sha256"
    digest, tag = val.shift
    collector[tag] = Checksum.new(:sha1, digest)
  end
end

class Pathname
  def sha1
    require "digest/sha1"
    odeprecated "Pathname#sha1", "Pathname#sha256"
    incremental_hash(Digest::SHA1)
  end
end
