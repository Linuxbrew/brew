#:  * `log` [<git-log-options>] <formula> ...:
#:    Show the git log for the given formulae. Options that `git-log`(1)
#:    recognizes can be passed before the formula list.

require "formula"

module Homebrew
  module_function

  def log
    if ARGV.named.empty?
      cd HOMEBREW_REPOSITORY
      git_log
    else
      path = Formulary.path(ARGV.named.first)
      cd path.dirname # supports taps
      git_log path
    end
  end

  def git_log(path = nil)
    if File.exist? "#{`git rev-parse --show-toplevel`.chomp}/.git/shallow"
      opoo <<-EOS.undent
        The git repository is a shallow clone therefore the filtering may be incorrect.
        Use `git fetch --unshallow` to get the full repository.
      EOS
    end
    args = ARGV.options_only
    args += ["--follow", "--", path] unless path.nil?
    exec "git", "log", *args
  end
end
