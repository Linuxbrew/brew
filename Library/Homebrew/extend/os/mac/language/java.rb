module Language
  module Java
    def self.java_home_cmd(version = nil)
      version_flag = " --version #{version}" if version
      "/usr/libexec/java_home#{version_flag}"
    end

    def self.java_home(version = nil)
      cmd = Language::Java.java_home_cmd(version)
      Pathname.new Utils.popen_read(cmd).chomp
    end

    # @private
    def self.java_home_shell(version = nil)
      "$(#{java_home_cmd(version)})"
    end
  end
end
