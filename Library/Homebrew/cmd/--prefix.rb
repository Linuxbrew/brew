#:  * `--prefix`:
#:    Display Homebrew's install path. *Default:* `/usr/local`
#:
#:  * `--prefix` <formula>:
#:    Display the location in the cellar where <formula> is or would be installed.

module Homebrew
  module_function

  def __prefix
    if ARGV.named.empty?
      puts HOMEBREW_PREFIX
    else
      puts ARGV.resolved_formulae.map { |f| f.opt_prefix.exist? ? f.opt_prefix : f.installed_prefix }
    end
  end
end
