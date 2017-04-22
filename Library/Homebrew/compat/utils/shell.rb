module Utils
  module Shell
    def self.shell_profile
      odeprecated "Utils::Shell.shell_profile", "Utils::Shell.profile"
      Utils::Shell.profile
    end
  end
end
