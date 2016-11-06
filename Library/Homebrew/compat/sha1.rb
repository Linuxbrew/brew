class Formula
  def self.sha1(_val)
    odisabled "Formula.sha1", "Formula.sha256"
  end
end

class SoftwareSpec
  def sha1(_val)
    odisabled "SoftwareSpec#sha1", "SoftwareSpec#sha256"
  end
end

class Resource
  def sha1(_val)
    odisabled "Resource#sha1", "Resource#sha256"
  end
end

class BottleSpecification
  def sha1(_val)
    odisabled "BottleSpecification#sha1", "BottleSpecification#sha256"
  end
end

class Pathname
  def sha1
    odisabled "Pathname#sha1", "Pathname#sha256"
  end
end
