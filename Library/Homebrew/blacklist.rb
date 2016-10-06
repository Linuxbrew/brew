def blacklisted?(name)
  case name.downcase
  when "gem", /^rubygems?$/ then <<-EOS.undent
    Homebrew provides gem via: `brew install ruby`.
    EOS
  when "tex", "tex-live", "texlive", "latex" then <<-EOS.undent
    Installing TeX from source is weird and gross, requires a lot of patches,
    and only builds 32-bit (and thus can't use Homebrew dependencies)

    We recommend using a MacTeX distribution: https://www.tug.org/mactex/

    You can install it with Homebrew-Cask:
      brew cask install mactex
    EOS
  when "pip" then <<-EOS.undent
    Homebrew provides pip via: `brew install python`. However you will then
    have two Pythons installed on your Mac, so alternatively you can install
    pip via the instructions at:
      #{Formatter.url("https://pip.readthedocs.io/en/stable/installing/")}
    EOS
  when "pil" then <<-EOS.undent
    Instead of PIL, consider `pip install pillow` or `brew install Homebrew/python/pillow`.
    EOS
  when "macruby" then <<-EOS.undent
    MacRuby is not packaged and is on an indefinite development hiatus.
    You can read more about it at:
      #{Formatter.url("https://github.com/MacRuby/MacRuby")}
    EOS
  when /(lib)?lzma/
    "lzma is now part of the xz formula."
  when "gtest", "googletest", "google-test" then <<-EOS.undent
    Installing gtest system-wide is not recommended; it should be vendored
    in your projects that use it.
    EOS
  when "gmock", "googlemock", "google-mock" then <<-EOS.undent
    Installing gmock system-wide is not recommended; it should be vendored
    in your projects that use it.
    EOS
  when "sshpass" then <<-EOS.undent
    We won't add sshpass because it makes it too easy for novice SSH users to
    ruin SSH's security.
    EOS
  when "gsutil" then <<-EOS.undent
    Install gsutil with `pip install gsutil`
    EOS
  when "clojure" then <<-EOS.undent
    Clojure isn't really a program but a library managed as part of a
    project and Leiningen is the user interface to that library.

    To install Clojure you should install Leiningen:
      brew install leiningen
    and then follow the tutorial:
      #{Formatter.url("https://github.com/technomancy/leiningen/blob/stable/doc/TUTORIAL.md")}
    EOS
  when "osmium" then <<-EOS.undent
    The creator of Osmium requests that it not be packaged and that people
    use the GitHub master branch instead.
    EOS
  when "gfortran" then <<-EOS.undent
    GNU Fortran is now provided as part of GCC, and can be installed with:
      brew install gcc
    EOS
  when "play" then <<-EOS.undent
    Play 2.3 replaces the play command with activator:
      brew install typesafe-activator

    You can read more about this change at:
      #{Formatter.url("https://www.playframework.com/documentation/2.3.x/Migration23")}
      #{Formatter.url("https://www.playframework.com/documentation/2.3.x/Highlights23")}
    EOS
  when "haskell-platform" then <<-EOS.undent
    We no longer package haskell-platform. Consider installing ghc
    and cabal-install instead:
      brew install ghc cabal-install

    You can install with Homebrew-Cask:
      brew cask install haskell-platform
    EOS
  when "mysqldump-secure" then <<-EOS.undent
    The creator of mysqldump-secure tried to game our popularity metrics.
    EOS
  when "ngrok" then <<-EOS.undent
    Upstream sunsetted 1.x in March 2016 and 2.x is not open-source.

    If you wish to use the 2.x release you can install with Homebrew-Cask:
      brew cask install ngrok
    EOS
  end
end
alias generic_blacklisted? blacklisted?

require "extend/os/blacklist"
