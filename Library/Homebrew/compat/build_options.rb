class BuildOptions
  def build_32_bit?
    odeprecated "build.build_32_bit?"
    include?("32-bit") && option_defined?("32-bit")
  end

  def build_bottle?
    odeprecated "build.build_bottle?", "build.bottle?"
    bottle?
  end
end
