#:  * `shellenv`:
#:    Prints export statements - run them in a shell and this installation of
#:    Homebrew will be included into your PATH, MANPATH, and INFOPATH.
#:
#:    HOMEBREW_PREFIX, HOMEBREW_CELLAR and HOMEBREW_REPOSITORY are also exported
#:    to save multiple queries of those variables.
#:
#:    Consider adding evaluating the output in your dotfiles (e.g. `~/.profile`)
#:    with `eval $(brew shellenv)`

homebrew-shellenv() {
  echo "export HOMEBREW_PREFIX=\"$HOMEBREW_PREFIX\""
  echo "export HOMEBREW_CELLAR=\"$HOMEBREW_CELLAR\""
  echo "export HOMEBREW_REPOSITORY=\"$HOMEBREW_REPOSITORY\""
  echo "export PATH=\"$HOMEBREW_PREFIX/bin:$HOMEBREW_PREFIX/sbin:\$PATH\""
  echo "export MANPATH=\"$HOMEBREW_PREFIX/share/man:\$MANPATH\""
  echo "export INFOPATH=\"$HOMEBREW_PREFIX/share/info:\$INFOPATH\""
}
