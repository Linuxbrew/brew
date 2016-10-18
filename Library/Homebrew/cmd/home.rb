#:  * `home`:
#:    Open Homebrew's own homepage in a browser.
#:
#:  * `home` <formula>:
#:    Open <formula>'s homepage in a browser.

module Homebrew
  module_function

  def home
    if ARGV.named.empty?
      exec_browser HOMEBREW_WWW
    else
      exec_browser(*ARGV.formulae.map(&:homepage))
    end
  end
end
