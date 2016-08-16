module SharedEnvExtension
  def no_weak_imports?
    return false unless compiler == :clang
    MacOS::Xcode.version >= "8.0" || MacOS::CLT.version >= "8.0"
  end
end
