class BuildOptions
  def build_32_bit?
    # odeprecated "build.build_32_bit?"
    include?("32-bit") && option_defined?("32-bit")
  end
end
