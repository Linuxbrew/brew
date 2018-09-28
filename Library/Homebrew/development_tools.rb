# @private
class DevelopmentTools
  class << self
    def locate(tool)
      # Don't call tools (cc, make, strip, etc.) directly!
      # Give the name of the binary you look for as a string to this method
      # in order to get the full path back as a Pathname.
      (@locate ||= {}).fetch(tool) do |key|
        @locate[key] = if File.executable?(path = "/usr/bin/#{tool}")
          Pathname.new path
        # Homebrew GCCs most frequently; much faster to check this before xcrun
        elsif (path = HOMEBREW_PREFIX/"bin/#{tool}").executable?
          path
        end
      end
    end

    def installed?
      locate("clang") || locate("gcc")
    end

    def installation_instructions
      "Install Clang or brew install gcc"
    end
    alias custom_installation_instructions installation_instructions

    def default_cc
      cc = DevelopmentTools.locate "cc"
      begin
        cc.realpath.basename.to_s
      rescue
        nil
      end
    end

    def default_compiler
      :clang
    end

    def gcc_4_0_build_version
      @gcc_4_0_build_version ||= begin
        if (path = locate("gcc-4.0")) &&
           build_version = `#{path} --version 2>/dev/null`[/build (\d{4,})/, 1]
          Version.new build_version
        else
          Version::NULL
        end
      end
    end

    def gcc_4_2_build_version
      @gcc_4_2_build_version ||= begin
        gcc = locate("gcc-4.2") || HOMEBREW_PREFIX/"opt/apple-gcc42/bin/gcc-4.2"
        if gcc.exist? && !gcc.realpath.basename.to_s.start_with?("llvm") &&
           build_version = `#{gcc} --version 2>/dev/null`[/build (\d{4,})/, 1]
          Version.new build_version
        else
          Version::NULL
        end
      end
    end

    def clang_version
      @clang_version ||= begin
        if (path = locate("clang")) &&
           build_version = `#{path} --version`[/(?:clang|LLVM) version (\d+\.\d)/, 1]
          Version.new build_version
        else
          Version::NULL
        end
      end
    end

    def clang_build_version
      @clang_build_version ||= begin
        if (path = locate("clang")) &&
           build_version = `#{path} --version`[%r{clang(-| version [^ ]+ \(tags/RELEASE_)(\d{2,})}, 2]
          Version.new build_version
        else
          Version::NULL
        end
      end
    end

    def llvm_clang_build_version
      @llvm_clang_build_version ||= begin
        path = Formulary.factory("llvm").opt_prefix/"bin/clang"
        if path.executable? &&
           build_version = `#{path} --version`[/clang version (\d\.\d\.\d)/, 1]
          Version.new build_version
        else
          Version::NULL
        end
      end
    end

    def non_apple_gcc_version(cc)
      (@non_apple_gcc_version ||= {}).fetch(cc) do
        path = HOMEBREW_PREFIX/"opt/gcc/bin"/cc
        path = locate(cc) unless path.exist?
        version = if path &&
                     build_version = `#{path} --version`[/gcc(?:(?:-\d(?:\.\d)?)? \(.+\))? (\d\.\d\.\d)/, 1]
          Version.new build_version
        else
          Version::NULL
        end
        @non_apple_gcc_version[cc] = version
      end
    end

    def clear_version_cache
      @gcc_4_0_build_version = @gcc_4_2_build_version = nil
      @clang_version = @clang_build_version = nil
      @non_apple_gcc_version = {}
    end

    def curl_handles_most_https_certificates?
      true
    end

    def subversion_handles_most_https_certificates?
      true
    end
  end
end

require "extend/os/development_tools"
