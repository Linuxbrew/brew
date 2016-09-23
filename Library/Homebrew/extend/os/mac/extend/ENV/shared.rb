module SharedEnvExtension
  def no_weak_imports_support?
    return false unless compiler == :clang

    return false if MacOS::Xcode.version && MacOS::Xcode.version < "8.0"
    return false if MacOS::CLT.version && MacOS::CLT.version < "8.0"

    true
  end
end
