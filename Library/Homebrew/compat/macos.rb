require "development_tools"

if OS.mac?
  MACOS_FULL_VERSION = OS::Mac.full_version.to_s.freeze
  MACOS_VERSION = OS::Mac.version.to_s.freeze
end

module OS
  module Mac
    module_function

    def xcode_folder
      odisabled "MacOS.xcode_folder", "MacOS::Xcode.folder"
    end

    def xcode_prefix
      odisabled "MacOS.xcode_prefix", "MacOS::Xcode.prefix"
    end

    def xcode_installed?
      odisabled "MacOS.xcode_installed?", "MacOS::Xcode.installed?"
    end

    def xcode_version
      odisabled "MacOS.xcode_version", "MacOS::Xcode.version"
    end

    def clt_installed?
      odisabled "MacOS.clt_installed?", "MacOS::CLT.installed?"
    end

    def clt_version?
      odisabled "MacOS.clt_version?", "MacOS::CLT.version"
    end

    def x11_installed?
      odisabled "MacOS.x11_installed?", "MacOS::X11.installed?"
    end

    def x11_prefix
      odisabled "MacOS.x11_prefix", "MacOS::X11.prefix"
    end

    def leopard?
      odisabled "MacOS.leopard?", "'MacOS.version == :leopard'"
    end

    def snow_leopard?
      odisabled "MacOS.snow_leopard?", "'MacOS.version >= :snow_leopard'"
    end

    def snow_leopard_or_newer?
      odisabled "MacOS.snow_leopard_or_newer?", "'MacOS.version >= :snow_leopard'"
    end

    def lion?
      odisabled "MacOS.lion?", "'MacOS.version >= :lion'"
    end

    def lion_or_newer?
      odisabled "MacOS.lion_or_newer?", "'MacOS.version >= :lion'"
    end

    def mountain_lion?
      odisabled "MacOS.mountain_lion?", "'MacOS.version >= :mountain_lion'"
    end

    def mountain_lion_or_newer?
      odisabled "MacOS.mountain_lion_or_newer?", "'MacOS.version >= :mountain_lion'"
    end

    def macports_or_fink_installed?
      odisabled "MacOS.macports_or_fink_installed?", "!MacOS.macports_or_fink.empty?"
    end

    def locate(_)
      odisabled "MacOS.locate", "DevelopmentTools.locate"
    end

    def default_cc
      odisabled "MacOS.default_cc", "DevelopmentTools.default_cc"
    end

    def default_compiler
      odisabled "MacOS.default_compiler", "DevelopmentTools.default_compiler"
    end

    def gcc_40_build_version
      odisabled "MacOS.gcc_40_build_version", "DevelopmentTools.gcc_4_0_build_version"
    end

    def gcc_4_0_build_version
      odisabled "MacOS.gcc_4_0_build_version", "DevelopmentTools.gcc_4_0_build_version"
    end

    def gcc_42_build_version
      odisabled "MacOS.gcc_42_build_version", "DevelopmentTools.gcc_4_2_build_version"
    end

    def gcc_build_version
      odisabled "MacOS.gcc_build_version", "DevelopmentTools.gcc_4_2_build_version"
    end

    def llvm_build_version
      odisabled "MacOS.llvm_build_version"
    end

    def clang_version
      odisabled "MacOS.clang_version", "DevelopmentTools.clang_version"
    end

    def clang_build_version
      odisabled "MacOS.clang_build_version", "DevelopmentTools.clang_build_version"
    end

    def has_apple_developer_tools?
      odisabled "MacOS.has_apple_developer_tools?", "DevelopmentTools.installed?"
    end

    def release
      odisabled "MacOS.release", "MacOS.version"
    end
  end
end
