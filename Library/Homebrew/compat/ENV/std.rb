module Stdenv
  def fast
    odisabled "ENV.fast"
  end

  def O4
    odisabled "ENV.O4"
  end

  def Og
    odisabled "ENV.Og"
  end

  def gcc_4_0_1
    odisabled "ENV.gcc_4_0_1", "ENV.gcc_4_0"
  end

  def gcc
    odisabled "ENV.gcc", "ENV.gcc_4_2"
  end

  def libpng
    odisabled "ENV.libpng", "ENV.x11"
  end
end
