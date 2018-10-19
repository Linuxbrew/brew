unless ENV["HOMEBREW_BREW_FILE"]
  raise "HOMEBREW_BREW_FILE was not exported! Please call bin/brew directly!"
end

# Path to `bin/brew` main executable in `HOMEBREW_PREFIX`
HOMEBREW_BREW_FILE = Pathname.new(ENV["HOMEBREW_BREW_FILE"])

# Where we link under
HOMEBREW_PREFIX = Pathname.new(ENV["HOMEBREW_PREFIX"])

# Where `.git` is found
HOMEBREW_REPOSITORY = Pathname.new(ENV["HOMEBREW_REPOSITORY"])

# Where we store most of Homebrew, taps, and various metadata
HOMEBREW_LIBRARY = Pathname.new(ENV["HOMEBREW_LIBRARY"])

# Where shim scripts for various build and SCM tools are stored
HOMEBREW_SHIMS_PATH = HOMEBREW_LIBRARY/"Homebrew/shims"

# Where we store symlinks to currently linked kegs
HOMEBREW_LINKED_KEGS = HOMEBREW_PREFIX/"var/homebrew/linked"

# Where we store symlinks to currently version-pinned kegs
HOMEBREW_PINNED_KEGS = HOMEBREW_PREFIX/"var/homebrew/pinned"

# Where we store lock files
HOMEBREW_LOCKS = HOMEBREW_PREFIX/"var/homebrew/locks"

# Where we store built products
HOMEBREW_CELLAR = Pathname.new(ENV["HOMEBREW_CELLAR"])

# Where downloads (bottles, source tarballs, etc.) are cached
HOMEBREW_CACHE = Pathname.new(ENV["HOMEBREW_CACHE"])

# Where brews installed via URL are cached
HOMEBREW_CACHE_FORMULA = HOMEBREW_CACHE/"Formula"

# Where build, postinstall, and test logs of formulae are written to
HOMEBREW_LOGS = Pathname.new(ENV["HOMEBREW_LOGS"] || "~/Library/Logs/Homebrew/").expand_path

# Must use `/tmp` instead of `TMPDIR` because long paths break Unix domain sockets
HOMEBREW_TEMP = begin
  # /tmp fallback is here for people auto-updating from a version where
  # HOMEBREW_TEMP isn't set.
  tmp = Pathname.new(ENV["HOMEBREW_TEMP"] || "/tmp")
  tmp.mkpath unless tmp.exist?
  tmp.realpath
end
