module Homebrew
  DEFAULT_PREFIX = if ENV["HOMEBREW_FORCE_HOMEBREW_ON_LINUX"]
    "/usr/local".freeze
  else
    "/home/linuxbrew/.linuxbrew".freeze
  end
end
