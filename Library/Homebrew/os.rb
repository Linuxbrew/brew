require "rbconfig"

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
  
  GITHUB_USER = "SuperNEMO-DBD".freeze
  ISSUES_URL = "https://github.com/#{GITHUB_USER}/brew/blob/master/share/doc/homebrew/Troubleshooting.md#troubleshooting".freeze

  if OS.mac?
    require "os/mac"
    NAME = "darwin".freeze
    # Don't tell people to report issues on unsupported versions of macOS.
    if !OS::Mac.prerelease? && !OS::Mac.outdated_release?
      ISSUES_URL = "https://docs.brew.sh/Troubleshooting.html".freeze
    end
    PATH_OPEN = "/usr/bin/open".freeze
    PATH_PATCH = "/usr/bin/patch".freeze
    # compatibility
    ::MACOS_FULL_VERSION = OS::Mac.full_version.to_s.freeze
    ::MACOS_VERSION = OS::Mac.version.to_s.freeze
  elsif OS.linux?
    require "os/mac"
    NAME = "linux".freeze
    PATH_OPEN = "xdg-open".freeze
    PATH_PATCH = "patch".freeze
    # compatibility
    ::MACOS_FULL_VERSION = ::MACOS_VERSION = "0".freeze
  else
    PATH_PATCH = "patch".freeze
  end
end
