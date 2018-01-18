class Formula
  def fails_with_llvm(_msg = nil, _data = nil)
    odisabled "Formula#fails_with_llvm in install"
  end

  def self.fails_with_llvm(_msg = nil, _data = {})
    odisabled "Formula.fails_with_llvm"
  end
end
