module HomebrewArgvExtension
  def build_32_bit?
    odeprecated "ARGV.build_32_bit?"
    include? "--32-bit"
  end
end
