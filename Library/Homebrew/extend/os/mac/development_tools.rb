require "os/mac/xcode"

# @private
class DevelopmentTools
  class << self
    alias generic_locate locate
    undef installed?, default_compiler, curl_handles_most_https_certificates?,
          subversion_handles_most_https_certificates?

    def locate(tool)
      (@locate ||= {}).fetch(tool) do |key|
        @locate[key] = if (located_tool = generic_locate(tool))
          located_tool
        elsif MacOS.version > :tiger
          path = Utils.popen_read("/usr/bin/xcrun", "-no-cache", "-find", tool, err: :close).chomp
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

    def default_compiler
      case default_cc
      # if GCC 4.2 is installed, e.g. via Tigerbrew, prefer it
      # over the system's GCC 4.0
      when /^gcc-4\.0/ then gcc_4_2_build_version ? :gcc_4_2 : :gcc_4_0
      when /^gcc/ then :gcc_4_2
      when "clang" then :clang
      else
        # guess :(
        if MacOS::Xcode.version >= "4.3"
          :clang
        else
          :gcc_4_2
        end
      end
    end

    def curl_handles_most_https_certificates?
      # The system Curl is too old for some modern HTTPS certificates on
      # older macOS versions.
      ENV["HOMEBREW_SYSTEM_CURL_TOO_OLD"].nil?
    end

    def subversion_handles_most_https_certificates?
      # The system Subversion is too old for some HTTPS certificates on
      # older macOS versions.
      MacOS.version >= :sierra
    end

    def installation_instructions
      if MacOS.version >= "10.9"
        <<~EOS
          Install the Command Line Tools:
            xcode-select --install
        EOS
      elsif MacOS.version == "10.8" || MacOS.version == "10.7"
        <<~EOS
          Install the Command Line Tools from
            https://developer.apple.com/download/more/
          or via Xcode's preferences.
        EOS
      else
        <<~EOS
          Install Xcode from
            https://developer.apple.com/download/more/
        EOS
      end
    end

    def custom_installation_instructions
      if MacOS.version > :leopard
        <<~EOS
          Install GNU's GCC
            brew install gcc
        EOS
      elsif MacOS.version > :tiger
        <<~EOS
          Install GNU's GCC
            brew install gcc@4.6
        EOS
      else
        # Tiger doesn't ship with apple-gcc42, and this is required to build
        # some software that doesn't build properly with FSF GCC.
        <<~EOS
          Install Apple's GCC
            brew install apple-gcc42
          or GNU's GCC
            brew install gcc@4.6
        EOS
      end
    end
  end
end
