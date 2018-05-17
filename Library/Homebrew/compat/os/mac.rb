module OS
  module Mac
    module_function

    def release
      odeprecated "MacOS.release", "MacOS.version"
      version
    end
  end
end
