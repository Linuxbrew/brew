module Hardware
  def self.oldest_cpu
    if MacOS.version >= :mojave
      :nehalem
    else
      generic_oldest_cpu
    end
  end
end
