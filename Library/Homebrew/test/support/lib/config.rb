unless ENV["HOMEBREW_BREW_FILE"]
  raise "HOMEBREW_BREW_FILE was not exported! Please call bin/brew directly!"
end

require "pathname"

HOMEBREW_BREW_FILE = Pathname.new(ENV["HOMEBREW_BREW_FILE"])

TEST_TMPDIR = ENV.fetch("HOMEBREW_TEST_TMPDIR") do |k|
  dir = Dir.mktmpdir("homebrew-tests-", ENV["HOMEBREW_TEMP"] || "/tmp")
  at_exit do
    # Child processes inherit this at_exit handler, but we don't want them
    # to clean TEST_TMPDIR up prematurely (i.e., when they exit early for a test).
    FileUtils.remove_entry(dir) unless ENV["HOMEBREW_TEST_NO_EXIT_CLEANUP"]
  end
  ENV[k] = dir
end

# Paths pointing into the Homebrew code base that persist across test runs
HOMEBREW_SHIMS_PATH    = HOMEBREW_LIBRARY_PATH.parent/"Homebrew/shims"

# Paths redirected to a temporary directory and wiped at the end of the test run
HOMEBREW_PREFIX        = Pathname(TEST_TMPDIR)/"prefix"
HOMEBREW_REPOSITORY    = HOMEBREW_PREFIX
HOMEBREW_LIBRARY       = HOMEBREW_REPOSITORY/"Library"
HOMEBREW_CACHE         = HOMEBREW_PREFIX.parent/"cache"
HOMEBREW_CACHE_FORMULA = HOMEBREW_PREFIX.parent/"formula_cache"
HOMEBREW_LINKED_KEGS   = HOMEBREW_PREFIX.parent/"linked"
HOMEBREW_PINNED_KEGS   = HOMEBREW_PREFIX.parent/"pinned"
HOMEBREW_LOCKS         = HOMEBREW_PREFIX.parent/"locks"
HOMEBREW_CELLAR        = HOMEBREW_PREFIX.parent/"cellar"
HOMEBREW_LOGS          = HOMEBREW_PREFIX.parent/"logs"
HOMEBREW_TEMP          = HOMEBREW_PREFIX.parent/"temp"

TEST_FIXTURE_DIR = HOMEBREW_LIBRARY_PATH/"test/support/fixtures"

TESTBALL_SHA256 = "91e3f7930c98d7ccfb288e115ed52d06b0e5bc16fec7dce8bdda86530027067b".freeze
TESTBALL_PATCHES_SHA256 = "799c2d551ac5c3a5759bea7796631a7906a6a24435b52261a317133a0bfb34d9".freeze
PATCH_A_SHA256 = "83404f4936d3257e65f176c4ffb5a5b8d6edd644a21c8d8dcc73e22a6d28fcfa".freeze
PATCH_B_SHA256 = "57958271bb802a59452d0816e0670d16c8b70bdf6530bcf6f78726489ad89b90".freeze

TEST_SHA1   = "deadbeefdeadbeefdeadbeefdeadbeefdeadbeef".freeze
TEST_SHA256 = "deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef".freeze
