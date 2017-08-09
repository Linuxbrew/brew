#:  * `--repository`:
#:    Display where Homebrew's `.git` directory is located.
#:
#:  * `--repository` <user>`/`<repo>:
#:    Display where tap <user>`/`<repo>'s directory is located.

require "tap"

module Homebrew
  module_function

  def __repository
    if ARGV.named.empty?
      puts HOMEBREW_REPOSITORY
    else
      puts ARGV.named.map { |tap| Tap.fetch(tap).path }
    end
  end
end
