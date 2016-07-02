HOMEBREW_CACHE = Pathname.new(ENV["HOMEBREW_CACHE"] || "~/Library/Caches/Homebrew").expand_path

# Where brews installed via URL are cached
HOMEBREW_CACHE_FORMULA = HOMEBREW_CACHE/"Formula"

if ENV["HOMEBREW_BREW_FILE"]
  HOMEBREW_BREW_FILE = Pathname.new(ENV["HOMEBREW_BREW_FILE"])
else
  odie "HOMEBREW_BREW_FILE was not exported! Please call bin/brew directly!"
end

# Where we link under
HOMEBREW_PREFIX = Pathname.new(ENV["HOMEBREW_PREFIX"])

# Where .git is found
HOMEBREW_REPOSITORY = Pathname.new(ENV["HOMEBREW_REPOSITORY"])

HOMEBREW_LIBRARY = Pathname.new(ENV["HOMEBREW_LIBRARY"])
HOMEBREW_ENV_PATH = HOMEBREW_LIBRARY/"ENV"

# Where we store lock files
HOMEBREW_LOCK_DIR = HOMEBREW_LIBRARY/"Locks"

# Where we store built products
HOMEBREW_CELLAR = Pathname.new(ENV["HOMEBREW_CELLAR"])

HOMEBREW_LOGS = Pathname.new(ENV["HOMEBREW_LOGS"] || "~/Library/Logs/Homebrew/").expand_path

# Must use /tmp instead of $TMPDIR because long paths break Unix domain sockets
HOMEBREW_TEMP = Pathname.new(ENV.fetch("HOMEBREW_TEMP", "/tmp"))

unless defined? HOMEBREW_LIBRARY_PATH
  HOMEBREW_LIBRARY_PATH = Pathname.new(__FILE__).realpath.parent
end

HOMEBREW_LOAD_PATH = HOMEBREW_LIBRARY_PATH
