class BuildOptions
  def build_32_bit?
    odisabled "build.build_32_bit?"
  end

  def build_bottle?
    odisabled "build.build_bottle?", "build.bottle?"
  end
end
