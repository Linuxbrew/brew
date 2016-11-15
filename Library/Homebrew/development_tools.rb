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
      which("clang") || which("gcc")
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
      if default_cc =~ /^gcc/
        :gcc
      else
        :clang
      end
    end

    def gcc_40_build_version
      @gcc_40_build_version ||=
        if (path = locate("gcc-4.0")) &&
           build_version = `#{path} --version 2>/dev/null`[/build (\d{4,})/, 1]
          Version.new build_version
        else
          Version::NULL
        end
    end
    alias gcc_4_0_build_version gcc_40_build_version

    def gcc_42_build_version
      @gcc_42_build_version ||=
        begin
          gcc = locate("gcc-4.2") || HOMEBREW_PREFIX.join("opt/apple-gcc42/bin/gcc-4.2")
          if gcc.exist? && !gcc.realpath.basename.to_s.start_with?("llvm")&&
             build_version = `#{gcc} --version 2>/dev/null`[/build (\d{4,})/, 1]
            Version.new build_version
          else
            Version::NULL
          end
        end
    end
    alias gcc_build_version gcc_42_build_version

    def clang_version
      @clang_version ||=
        if (path = locate("clang")) &&
           build_version = `#{path} --version`[/(?:clang|LLVM) version (\d\.\d)/, 1]
          Version.new build_version
        else
          Version::NULL
        end
    end

    def clang_build_version
      @clang_build_version ||=
        if (path = locate("clang")) &&
           build_version = `#{path} --version`[/clang-(\d{2,})/, 1]
          Version.new build_version
        else
          Version::NULL
        end
    end

    def non_apple_gcc_version(cc)
      (@non_apple_gcc_version ||= {}).fetch(cc) do
        path = HOMEBREW_PREFIX.join("opt", "gcc", "bin", cc)
        path = locate(cc) unless path.exist?
        version = if path &&
                     build_version = `#{path} --version`[/gcc(?:-\d(?:\.\d)? \(.+\))? (\d\.\d\.\d)/, 1]
          Version.new build_version
        else
          Version::NULL
        end
        @non_apple_gcc_version[cc] = version
      end
    end

    def clear_version_cache
      @gcc_40_build_version = @gcc_42_build_version = nil
      @clang_version = @clang_build_version = nil
      @non_apple_gcc_version = {}
    end

    def tar_supports_xz?
      false
    end
  end
end

require "extend/os/development_tools"
