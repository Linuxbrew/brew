#:  * `--version`:
#:    Print the version number of Homebrew to standard output and exit.

module Homebrew
  module_function

  def __version
    odie "This command does not take arguments." if ARGV.any?

    puts "Homebrew #{HOMEBREW_VERSION}"
    puts "Homebrew/homebrew-core #{CoreTap.instance.version_string}"
  end
end
