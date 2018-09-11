#:  * `shellenv`:
#:    Prints export statements - run them in a shell and this installation of
#:    Homebrew will be included into your PATH, MANPATH, and INFOPATH.
#:    Tip: have your dotfiles eval the output of this command

module Homebrew
  module_function

  def shellenv
    puts <<~EOS
      export PATH="#{HOMEBREW_PREFIX}/bin:#{HOMEBREW_PREFIX}/sbin:$PATH"
      export MANPATH="#{HOMEBREW_PREFIX}/share/man:$MANPATH"
      export INFOPATH="#{HOMEBREW_PREFIX}/share/info:$INFOPATH"
    EOS
  end
end
