module Hardware
  def self.oldest_cpu
    if MacOS.version >= :mojave
      :nehalem
    elsif MacOS.version >= :sierra
      :penryn
    else
      generic_oldest_cpu
    end
  end
end
