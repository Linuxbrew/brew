module Superenv
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

  def libxml2
    odeprecated "ENV.libxml2"
  end

  def minimal_optimization
    odeprecated "ENV.minimal_optimization"
  end

  def no_optimization
    odeprecated "ENV.no_optimization"
  end

  def enable_warnings
    odeprecated "ENV.enable_warnings"
  end

  def macosxsdk
    odeprecated "ENV.macosxsdk"
  end

  def remove_macosxsdk
    odeprecated "ENV.remove_macosxsdk"
  end
end
