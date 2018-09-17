module OS
  def self.mac?
    return false if ENV["HOMEBREW_TEST_GENERIC_OS"]

    RbConfig::CONFIG["host_os"].include? "darwin"
  end

  def self.linux?
    return false if ENV["HOMEBREW_TEST_GENERIC_OS"]

    RbConfig::CONFIG["host_os"].include? "linux"
  end

  ::OS_VERSION = ENV["HOMEBREW_OS_VERSION"]

  if OS.mac?
    require "os/mac"
    # Don't tell people to report issues on unsupported versions of macOS.
    if !OS::Mac.prerelease? && !OS::Mac.outdated_release?
      ISSUES_URL = "https://docs.brew.sh/Troubleshooting".freeze
    end
    PATH_OPEN = "/usr/bin/open".freeze
  elsif OS.linux?
    require "os/linux"
    ISSUES_URL = "https://github.com/Linuxbrew/brew/wiki/troubleshooting".freeze
    PATH_OPEN = "xdg-open".freeze
  end
end
