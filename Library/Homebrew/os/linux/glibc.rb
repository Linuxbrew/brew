module OS
  module Linux
    module Glibc
      module_function

      def system_version
        return @system_version if @system_version

        version = Utils.popen_read("/usr/bin/ldd", "--version")[/ (\d+\.\d+)/, 1]
        return Version::NULL unless version

        @system_version = Version.new version
      end
    end
  end
end
