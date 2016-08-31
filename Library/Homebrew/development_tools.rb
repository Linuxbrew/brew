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
    alias_method :custom_installation_instructions,
                 :installation_instructions

    def default_cc
      cc = DevelopmentTools.locate "cc"
      cc.realpath.basename.to_s rescue nil
    end

    def default_compiler
      return :gcc unless OS.mac?
      if default_cc =~ /^gcc/
        :gcc
      else
        :clang
      end
    end

    def gcc_40_build_version
      @gcc_40_build_version ||=
        if (path = locate("gcc-4.0"))
          `#{path} --version 2>/dev/null`[/build (\d{4,})/, 1].to_i
        end
    end
    alias_method :gcc_4_0_build_version, :gcc_40_build_version

    def gcc_42_build_version
      @gcc_42_build_version ||=
        begin
          gcc = locate("gcc-4.2") || HOMEBREW_PREFIX.join("opt/apple-gcc42/bin/gcc-4.2")
          if gcc.exist? && !gcc.realpath.basename.to_s.start_with?("llvm")
            `#{gcc} --version 2>/dev/null`[/build (\d{4,})/, 1].to_i
          end
        end
    end
    alias_method :gcc_build_version, :gcc_42_build_version

    def clang_version
      @clang_version ||=
        if (path = locate("clang"))
          `#{path} --version`[/(?:clang|LLVM) version (\d\.\d)/, 1]
        end
    end

    def clang_build_version
      @clang_build_version ||=
        if (path = locate("clang"))
          `#{path} --version`[/clang-(\d{2,})/, 1].to_i
        end
    end

    def non_apple_gcc_version(cc)
      (@non_apple_gcc_version ||= {}).fetch(cc) do
        path = HOMEBREW_PREFIX.join("opt", "gcc", "bin", cc)
        path = locate(cc) unless path.exist?
        path = locate(cc.delete("-.")) if OS.linux? && !path
        version = `#{path} --version`[/gcc(?:-\d(?:\.\d)?)? \(.+\) (\d\.\d\.\d)/, 1] if path
        @non_apple_gcc_version[cc] = version
      end
    end

    def clear_version_cache
      @gcc_40_build_version = @gcc_42_build_version = nil
      @clang_version = @clang_build_version = nil
      @non_apple_gcc_version = {}
    end
  end
end

require "extend/os/development_tools"
