class Formula
  def self.md5(_val)
    odisabled "Formula.md5", "Formula.sha256"
  end
end

class SoftwareSpec
  def md5(_val)
    odisabled "SoftwareSpec#md5", "SoftwareSpec#sha256"
  end
end

class Resource
  def md5(_val)
    odisabled "Resource#md5", "Resource#sha256"
  end
end

class Pathname
  def md5
    odisabled "Pathname#md5", "Pathname#sha256"
  end
end
