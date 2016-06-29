# @private
class DevelopmentTools
  class << self
    alias_method :original_locate, :locate
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

    def default_compiler
      case default_cc
      # if GCC 4.2 is installed, e.g. via Tigerbrew, prefer it
      # over the system's GCC 4.0
      when /^gcc-4.0/ then gcc_42_build_version ? :gcc : :gcc_4_0
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
  end
end
