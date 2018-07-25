# match taps' formulae, e.g. someuser/sometap/someformula
HOMEBREW_TAP_FORMULA_REGEX = %r{^([\w-]+)/([\w-]+)/([\w+-.@]+)$}
# match taps' casks, e.g. someuser/sometap/somecask
HOMEBREW_TAP_CASK_REGEX = %r{^([\w-]+)/([\w-]+)/([a-z0-9\-]+)$}
# match taps' directory paths, e.g. HOMEBREW_LIBRARY/Taps/someuser/sometap
HOMEBREW_TAP_DIR_REGEX = %r{#{Regexp.escape(HOMEBREW_LIBRARY)}/Taps/(?<user>[\w-]+)/(?<repo>[\w-]+)}
# match taps' formula paths, e.g. HOMEBREW_LIBRARY/Taps/someuser/sometap/someformula
HOMEBREW_TAP_PATH_REGEX = Regexp.new(HOMEBREW_TAP_DIR_REGEX.source + %r{(?:/.*)?$}.source)
# match official taps' casks, e.g. homebrew/cask/somecask or homebrew/cask-versions/somecask
HOMEBREW_CASK_TAP_CASK_REGEX = %r{^(?:([Cc]askroom)/(cask|versions)|(homebrew)/(cask|cask-[\w-]+))/([\w+-.]+)$}
