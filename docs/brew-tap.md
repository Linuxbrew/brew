# Taps (third-party repositories)

`brew tap` adds more repositories to the list of formulae that `brew` tracks, updates,
and installs from. By default, `tap` assumes that the repositories come from GitHub,
but the command isn't limited to any one location.

## The command (`brew tap`)

* `brew tap` without arguments lists the currently tapped repositories. For
  example:

```sh
$ brew tap
homebrew/core
mistydemeo/tigerbrew
dunn/emacs
```

* `brew tap <user/repo>` makes a shallow clone of the repository at
  https://github.com/user/repo. After that, `brew` will be able to work on
  those formulae as if they were in Homebrew's canonical repository. You can
  install and uninstall them with `brew [un]install`, and the formulae are
  automatically updated when you run `brew update`. (See below for details
  about how `brew tap` handles the names of repositories.)

* `brew tap <user/repo> <URL>` makes a shallow clone of the repository at URL.
  Unlike the one-argument version, URL is not assumed to be GitHub, and it
  doesn't have to be HTTP. Any location and any protocol that Git can handle is
  fine.

* Add `--full` to either the one- or two-argument invocations above, and Git
  will make a complete clone rather than a shallow one. Full is the default for
  Homebrew developers.

* `brew tap --repair` migrates tapped formulae from a symlink-based to
  directory-based structure. (This should only need to be run once.)

* `brew untap user/repo [user/repo user/repo ...]` removes the given taps. The
  repositories are deleted and `brew` will no longer be aware of their formulae.
  `brew untap` can handle multiple removals at once.

## Repository naming conventions and assumptions

* On GitHub, your repository must be named `homebrew-something` in order to use
  the one-argument form of `brew tap`.  The prefix 'homebrew-' is not optional.
  (The two-argument form doesn't have this limitation, but it forces you to
  give the full URL explicitly.)

* When you use `brew tap` on the command line, however, you can leave out the
  'homebrew-' prefix in commands.

  That is, `brew tap username/foobar` can be used as a shortcut for the long
  version: `brew tap username/homebrew-foobar`. `brew` will automatically add
  back the 'homebrew-' prefix whenever it's necessary.

## Formula duplicate names

If your tap contains a formula that is also present in
[`homebrew/core`](https://github.com/Homebrew/homebrew-core), that's fine,
but it means that you must install it explicitly by default.

If you would like to prioritize a tap over `homebrew/core`, you can use
`brew tap-pin username/repo` to pin the tap,
and use `brew tap-unpin username/repo` to revert the pin.

Whenever a `brew install foo` command is issued, `brew` will find which formula
to use by searching in the following order:

* pinned taps
* core formulae
* other taps

If you need a formula to be installed from a particular tap, you can use fully
qualified names to refer to them.

For example, you can create a tap for an alternative `vim` formula. Without
pinning it, the behaviour will be

```sh
brew install vim                     # installs from homebrew/core
brew install username/repo/vim       # installs from your custom repo
```

However if you pin the tap with `brew tap-pin username/repo`, you will need to
use `homebrew/core` to refer to the core formula.

```sh
brew install vim                     # installs from your custom repo
brew install homebrew/core/vim       # installs from homebrew/core
```

Do note that pinned taps are prioritized only when the formula name is directly
given by you, i.e. it will not influence formulae automatically installed as
dependencies.
