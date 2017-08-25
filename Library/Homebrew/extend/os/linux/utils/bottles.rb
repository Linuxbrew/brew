module Utils
  class Bottles
    class << self
      def tag
        @linux_kernel_version ||= Version.new Utils.popen_read("uname -r")
        if @linux_kernel_version >= "2.6.32"
          "#{ENV["HOMEBREW_PROCESSOR"]}_#{ENV["HOMEBREW_SYSTEM"]}"
        else
          "#{ENV["HOMEBREW_PROCESSOR"]}_#{ENV["HOMEBREW_SYSTEM"]}_glibc_2_19"
        end.downcase.to_sym
      end
    end
  end
end
