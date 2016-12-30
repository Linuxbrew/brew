module Stdenv
  def fast
    odeprecated "ENV.fast"
  end

  def O4
    odeprecated "ENV.O4"
  end

  def Og
    odeprecated "ENV.Og"
  end

  def gcc_4_0_1
    odeprecated "ENV.gcc_4_0_1", "ENV.gcc_4_0"
    gcc_4_0
  end

  def gcc
    odeprecated "ENV.gcc", "ENV.gcc_4_2"
    gcc_4_2
  end

  def libpng
    odeprecated "ENV.libpng", "ENV.x11"
  end
end
