def blacklisted?(name)
  case name.downcase
  when "xcode"
    if MacOS.version >= :lion
      <<-EOS.undent
      Xcode can be installed from the App Store.
      EOS
    else
      <<-EOS.undent
      Xcode can be installed from https://developer.apple.com/xcode/downloads/
      EOS
    end
  else
    generic_blacklisted?(name)
  end
end
