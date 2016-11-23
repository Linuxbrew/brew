require "os/mac/xcode"

# @private
class DevelopmentTools
  class << self
    alias original_locate locate
    def locate(tool)
      (@locate ||= {}).fetch(tool) do |key|
        @locate[key] = if (located_tool = original_locate(tool))
          located_tool
        elsif MacOS.version > :tiger
          path = Utils.popen_read("/usr/bin/xcrun", "-no-cache", "-find", tool).chomp
          Pathname.new(path) if File.executable?(path)
        end
      end
    end

    # Checks if the user has any developer tools installed, either via Xcode
    # or the CLT. Convenient for guarding against formula builds when building
    # is impossible.
    def installed?
      MacOS::Xcode.installed? || MacOS::CLT.installed?
    end

    def installation_instructions
      if MacOS.version >= "10.9"
        <<-EOS.undent
          Install the Command Line Tools:
            xcode-select --install
        EOS
      elsif MacOS.version == "10.8" || MacOS.version == "10.7"
        <<-EOS.undent
          Install the Command Line Tools from
            https://developer.apple.com/downloads/
          or via Xcode's preferences.
        EOS
      else
        <<-EOS.undent
          Install Xcode from
            https://developer.apple.com/xcode/downloads/
        EOS
      end
    end

    def custom_installation_instructions
      if MacOS.version > :tiger
        <<-EOS.undent
          Install GNU's GCC
            brew install gcc
        EOS
      else
        # Tiger doesn't ship with apple-gcc42, and this is required to build
        # some software that doesn't build properly with FSF GCC.
        <<-EOS.undent
          Install Apple's GCC
            brew install apple-gcc42
          or GNU's GCC
            brew install gcc
        EOS
      end
    end

    def default_compiler
      case default_cc
      # if GCC 4.2 is installed, e.g. via Tigerbrew, prefer it
      # over the system's GCC 4.0
      when /^gcc-4\.0/ then gcc_42_build_version ? :gcc : :gcc_4_0
      when /^gcc/ then :gcc
      when "clang" then :clang
      else
        # guess :(
        if MacOS::Xcode.version >= "4.3"
          :clang
        else
          :gcc
        end
      end
    end

    def tar_supports_xz?
      false
    end
  end
end
