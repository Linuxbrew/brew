require "development_tools"

module OS
  module Mac
    def xcode_folder
      Xcode.folder
    end

    def xcode_prefix
      Xcode.prefix
    end

    def xcode_installed?
      Xcode.installed?
    end

    def xcode_version
      Xcode.version
    end

    def clt_installed?
      CLT.installed?
    end

    def clt_version?
      CLT.version
    end

    def x11_installed?
      X11.installed?
    end

    def x11_prefix
      X11.prefix
    end

    def leopard?
      version == "10.5"
    end

    def snow_leopard?
      version >= "10.6"
    end
    alias_method :snow_leopard_or_newer?, :snow_leopard?

    def lion?
      version >= "10.7"
    end
    alias_method :lion_or_newer?, :lion?

    def mountain_lion?
      version >= "10.8"
    end
    alias_method :mountain_lion_or_newer?, :mountain_lion?

    def macports_or_fink_installed?
      !macports_or_fink.empty?
    end

    def locate(tool)
       DeveloperTools.locate(tool)
    end

    def default_cc
      DeveloperTools.default_cc
    end

    def default_compiler
      DeveloperTools.default_compiler
    end

    def gcc_40_build_version
      DeveloperTools.gcc_40_build_version
    end
    alias_method :gcc_4_0_build_version, :gcc_40_build_version

    def gcc_42_build_version
      DeveloperTools.gcc_42_build_version
    end
    alias_method :gcc_build_version, :gcc_42_build_version

    def llvm_build_version
      DeveloperTools.llvm_build_version
    end

    def clang_version
      DeveloperTools.llvm_build_version
    end

    def clang_build_version
      DeveloperTools.clang_build_version
    end
  end
end
