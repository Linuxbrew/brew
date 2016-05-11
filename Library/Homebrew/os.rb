module OS
  def self.mac?
    /darwin/i === RUBY_PLATFORM && !ENV["HOMEBREW_TEST_GENERIC_OS"]
  end

  def self.linux?
    /linux/i === RUBY_PLATFORM || /linux/i === RbConfig::CONFIG["host_os"]
  end

  require "os/mac"
  ::OS_VERSION = ENV["HOMEBREW_OS_VERSION"]

  if OS.mac?
    NAME = "darwin"
    GITHUB_USER = "Homebrew"
    ISSUES_URL = "https://git.io/brew-troubleshooting"
    PATH_OPEN = "/usr/bin/open"
    PATH_PATCH = "/usr/bin/patch"
    # compatibility
    ::MACOS_FULL_VERSION = OS::Mac.full_version.to_s
    ::MACOS_VERSION = OS::Mac.version.to_s
  elsif OS.linux?
    NAME = "linux"
    GITHUB_USER = "Linuxbrew"
    ISSUES_URL = "https://github.com/#{GITHUB_USER}/brew/blob/master/share/doc/homebrew/Troubleshooting.md#troubleshooting"
    PATH_OPEN = "xdg-open"
    PATH_PATCH = "patch"
    # compatibility
    ::MACOS_FULL_VERSION = ::MACOS_VERSION = "0"
  end
end
