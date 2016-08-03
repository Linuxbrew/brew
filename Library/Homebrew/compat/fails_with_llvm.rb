class Formula
  def fails_with_llvm(_msg = nil, _data = nil)
    odeprecated "Formula#fails_with_llvm in install"
  end

  def self.fails_with_llvm(_msg = nil, _data = {})
    odeprecated "Formula.fails_with_llvm"
  end
end
