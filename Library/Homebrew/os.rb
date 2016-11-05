module OS
  def self.mac?
    return false if ENV["HOMEBREW_TEST_GENERIC_OS"]
    RUBY_PLATFORM.to_s.downcase.include? "darwin"
  end

  def self.linux?
    return false if ENV["HOMEBREW_TEST_GENERIC_OS"]
    RUBY_PLATFORM.to_s.downcase.include? "linux"
  end

  ::OS_VERSION = ENV["HOMEBREW_OS_VERSION"]

  if OS.mac?
    require "os/mac"
    # Don't tell people to report issues on unsupported versions of macOS.
    if !OS::Mac.prerelease? && !OS::Mac.outdated_release?
      ISSUES_URL = "https://git.io/brew-troubleshooting".freeze
    end
    PATH_OPEN = "/usr/bin/open".freeze
    # compatibility
    ::MACOS_FULL_VERSION = OS::Mac.full_version.to_s.freeze
    ::MACOS_VERSION = OS::Mac.version.to_s.freeze
  elsif OS.linux?
    ISSUES_URL = "https://github.com/Linuxbrew/brew/wiki/troubleshooting".freeze
    PATH_OPEN = "xdg-open".freeze
  end
end
