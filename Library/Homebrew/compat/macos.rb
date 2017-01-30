require "development_tools"

module OS
  module Mac
    module_function

    def xcode_folder
      odeprecated "MacOS.xcode_folder", "MacOS::Xcode.folder"
      Xcode.folder
    end

    def xcode_prefix
      odeprecated "MacOS.xcode_prefix", "MacOS::Xcode.prefix"
      Xcode.prefix
    end

    def xcode_installed?
      odeprecated "MacOS.xcode_installed?", "MacOS::Xcode.installed?"
      Xcode.installed?
    end

    def xcode_version
      odeprecated "MacOS.xcode_version", "MacOS::Xcode.version"
      Xcode.version
    end

    def clt_installed?
      odeprecated "MacOS.clt_installed?", "MacOS::CLT.installed?"
      CLT.installed?
    end

    def clt_version?
      odeprecated "MacOS.clt_version?", "MacOS::CLT.version"
      CLT.version
    end

    def x11_installed?
      odeprecated "MacOS.x11_installed?", "MacOS::X11.installed?"
      X11.installed?
    end

    def x11_prefix
      odeprecated "MacOS.x11_prefix", "MacOS::X11.prefix"
      X11.prefix
    end

    def leopard?
      odeprecated "MacOS.leopard?", "'MacOS.version == :leopard'"
      version == :leopard
    end

    def snow_leopard?
      odeprecated "MacOS.snow_leopard?", "'MacOS.version >= :snow_leopard'"
      version >= :snow_leopard
    end

    def snow_leopard_or_newer?
      odeprecated "MacOS.snow_leopard_or_newer?", "'MacOS.version >= :snow_leopard'"
      version >= :snow_leopard
    end

    def lion?
      odeprecated "MacOS.lion?", "'MacOS.version >= :lion'"
      version >= :lion
    end

    def lion_or_newer?
      odeprecated "MacOS.lion_or_newer?", "'MacOS.version >= :lion'"
      version >= :lion
    end

    def mountain_lion?
      odeprecated "MacOS.mountain_lion?", "'MacOS.version >= :mountain_lion'"
      version >= :mountain_lion
    end

    def mountain_lion_or_newer?
      odeprecated "MacOS.mountain_lion_or_newer?", "'MacOS.version >= :mountain_lion'"
      version >= :mountain_lion
    end

    def macports_or_fink_installed?
      odeprecated "MacOS.macports_or_fink_installed?", "!MacOS.macports_or_fink.empty?"
      !macports_or_fink.empty?
    end

    def locate(tool)
      odeprecated "MacOS.locate", "DevelopmentTools.locate"
      DevelopmentTools.locate(tool)
    end

    def default_cc
      odeprecated "MacOS.default_cc", "DevelopmentTools.default_cc"
      DevelopmentTools.default_cc
    end

    def default_compiler
      odeprecated "MacOS.default_compiler", "DevelopmentTools.default_compiler"
      DevelopmentTools.default_compiler
    end

    def gcc_40_build_version
      odeprecated "MacOS.gcc_40_build_version", "DevelopmentTools.gcc_4_0_build_version"
      DevelopmentTools.gcc_4_0_build_version
    end

    def gcc_4_0_build_version
      odeprecated "MacOS.gcc_4_0_build_version", "DevelopmentTools.gcc_4_0_build_version"
      DevelopmentTools.gcc_4_0_build_version
    end

    def gcc_42_build_version
      odeprecated "MacOS.gcc_42_build_version", "DevelopmentTools.gcc_4_2_build_version"
      DevelopmentTools.gcc_4_2_build_version
    end

    def gcc_build_version
      odeprecated "MacOS.gcc_build_version", "DevelopmentTools.gcc_4_2_build_version"
      DevelopmentTools.gcc_4_2_build_version
    end

    def llvm_build_version
      odeprecated "MacOS.llvm_build_version"
    end

    def clang_version
      odeprecated "MacOS.clang_version", "DevelopmentTools.clang_version"
      DevelopmentTools.clang_version
    end

    def clang_build_version
      odeprecated "MacOS.clang_build_version", "DevelopmentTools.clang_build_version"
      DevelopmentTools.clang_build_version
    end

    def has_apple_developer_tools?
      odeprecated "MacOS.has_apple_developer_tools?", "DevelopmentTools.installed?"
      DevelopmentTools.installed?
    end

    def release
      odeprecated "MacOS.release", "MacOS.version"
      version
    end
  end
end
