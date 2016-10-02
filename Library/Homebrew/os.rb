module OS
  def self.mac?
    return false if ENV["HOMEBREW_TEST_GENERIC_OS"]
    RUBY_PLATFORM.to_s.downcase.include? "darwin"
  end

  def self.linux?
    return false if ENV["HOMEBREW_TEST_GENERIC_OS"]
    RUBY_PLATFORM.to_s.downcase.include?("linux") || RbConfig::CONFIG["host_os"].downcase.include?("linux")
  end

  require "os/mac"
  ::OS_VERSION = ENV["HOMEBREW_OS_VERSION"]

  if OS.mac?
    require "os/mac"
    NAME = "darwin".freeze
    GITHUB_USER = "Homebrew".freeze
    ISSUES_URL = "https://git.io/brew-troubleshooting".freeze
    PATH_OPEN = "/usr/bin/open".freeze
    PATH_PATCH = "/usr/bin/patch".freeze
    # compatibility
    ::MACOS_FULL_VERSION = OS::Mac.full_version.to_s.freeze
    ::MACOS_VERSION = OS::Mac.version.to_s.freeze
  elsif OS.linux?
    NAME = "linux".freeze
    GITHUB_USER = "Linuxbrew".freeze
    ISSUES_URL = "https://github.com/Linuxbrew/brew/blob/master/docs/Troubleshooting.md#troubleshooting".freeze
    PATH_OPEN = "xdg-open".freeze
    PATH_PATCH = "patch".freeze
    # compatibility
    ::MACOS_FULL_VERSION = ::MACOS_VERSION = "0".freeze
  end
end
