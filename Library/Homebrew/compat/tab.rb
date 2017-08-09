class Tab < OpenStruct
  def build_32_bit?
    odeprecated "Tab.build_32_bit?"
    include?("32-bit")
  end
end
