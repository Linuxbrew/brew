#:  * `--version`:
#:    Print the version number of Homebrew to standard output and exit.

module Homebrew
  module_function

  def __version
    # As a special case, `--version` is implemented directly in `brew.rb`. This
    # file merely serves as a container for the documentation. It also catches
    # the case where running `brew --version` with additional arguments would
    # produce a rather cryptic message about a non-existent `--version` command.
    raise UsageError
  end
end
