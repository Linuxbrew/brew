unless ENV["HOMEBREW_BREW_FILE"]
  raise "HOMEBREW_BREW_FILE was not exported! Please call bin/brew directly!"
end

# Path to `bin/brew` main executable in `HOMEBREW_PREFIX`
HOMEBREW_BREW_FILE = Pathname.new(ENV["HOMEBREW_BREW_FILE"])

class MissingEnvironmentVariables < RuntimeError; end

def get_env_or_raise(env)
  unless ENV[env]
    raise MissingEnvironmentVariables, "#{env} was not exported!"
  end
  ENV[env]
end

# Where we link under
HOMEBREW_PREFIX = Pathname.new(get_env_or_raise("HOMEBREW_PREFIX"))

# Where `.git` is found
HOMEBREW_REPOSITORY = Pathname.new(get_env_or_raise("HOMEBREW_REPOSITORY"))

# Where we store most of Homebrew, taps, and various metadata
HOMEBREW_LIBRARY = Pathname.new(get_env_or_raise("HOMEBREW_LIBRARY"))

# Where shim scripts for various build and SCM tools are stored
HOMEBREW_SHIMS_PATH = HOMEBREW_LIBRARY/"Homebrew/shims"

# Where we store symlinks to currently linked kegs
HOMEBREW_LINKED_KEGS = HOMEBREW_PREFIX/"var/homebrew/linked"

# Where we store symlinks to currently version-pinned kegs
HOMEBREW_PINNED_KEGS = HOMEBREW_PREFIX/"var/homebrew/pinned"

# Where we store lock files
HOMEBREW_LOCKS = HOMEBREW_PREFIX/"var/homebrew/locks"

# Where we store built products
HOMEBREW_CELLAR = Pathname.new(get_env_or_raise("HOMEBREW_CELLAR"))

# Where downloads (bottles, source tarballs, etc.) are cached
HOMEBREW_CACHE = Pathname.new(get_env_or_raise("HOMEBREW_CACHE"))

# Where brews installed via URL are cached
HOMEBREW_CACHE_FORMULA = HOMEBREW_CACHE/"Formula"

# Where build, postinstall, and test logs of formulae are written to
HOMEBREW_LOGS = Pathname.new(get_env_or_raise("HOMEBREW_LOGS")).expand_path

# Must use `/tmp` instead of `TMPDIR` because long paths break Unix domain sockets
HOMEBREW_TEMP = begin
  tmp = Pathname.new(get_env_or_raise("HOMEBREW_TEMP"))
  tmp.mkpath unless tmp.exist?
  tmp.realpath
end
