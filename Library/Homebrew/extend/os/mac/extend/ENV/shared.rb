module SharedEnvExtension
  def no_weak_import_support?
    return false unless compiler == :clang

    if MacOS::Xcode.version && MacOS::Xcode.version < "8.0"
      return false
    end

    if MacOS::CLT.version && MacOS::CLT.version < "8.0"
      return false
    end

    true
  end
end
