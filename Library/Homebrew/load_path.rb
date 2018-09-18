require "pathname"

HOMEBREW_LIBRARY_PATH = Pathname(__dir__).realpath

unless $LOAD_PATH.include?(HOMEBREW_LIBRARY_PATH.to_s)
  $LOAD_PATH.push(HOMEBREW_LIBRARY_PATH.to_s)
end

require "vendor/bundle-standalone/bundler/setup"
