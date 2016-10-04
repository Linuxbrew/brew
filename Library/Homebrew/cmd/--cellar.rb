#:  * `--cellar`:
#:    Display Homebrew's Cellar path. *Default:* `$(brew --prefix)/Cellar`, or if
#:    that directory doesn't exist, `$(brew --repository)/Cellar`.
#:
#:  * `--cellar` <formula>:
#:    Display the location in the cellar where <formula> would be installed,
#:    without any sort of versioned directory as the last path.

module Homebrew
  module_function

  def __cellar
    if ARGV.named.empty?
      puts HOMEBREW_CELLAR
    else
      puts ARGV.resolved_formulae.map(&:rack)
    end
  end
end
