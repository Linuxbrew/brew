module Superenv
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

  def libxml2
    odisabled "ENV.libxml2"
  end

  def minimal_optimization
    odisabled "ENV.minimal_optimization"
  end

  def no_optimization
    odisabled "ENV.no_optimization"
  end

  def enable_warnings
    odisabled "ENV.enable_warnings"
  end

  def macosxsdk
    odisabled "ENV.macosxsdk"
  end

  def remove_macosxsdk
    odisabled "ENV.remove_macosxsdk"
  end
end
