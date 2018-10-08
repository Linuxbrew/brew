# Homebrew Shell Completion

Homebrew comes with completion definitions for the `brew` command. Some packages also provide completion definitions for their own programs.

`zsh`, `bash` and `fish` are currently supported. (Homebrew provides `brew` completions for `zsh` and `bash`; `fish` provides its own `brew` completions.)

You must configure your shell to enable the completion support. This is because the Homebrew-managed completions are stored under `HOMEBREW_PREFIX`, which your system shell may not be aware of, and because it is difficult to automatically configure `bash` and `zsh` completions in a robust manner, so the Homebrew installer cannot do it for you.

## Configuring Completions in `bash`
To make Homebrew's completions available in `bash`, you must source the definitions as part of your shell startup. Add the following to your `~/.bashrc` file:

```sh
if type brew 2&>/dev/null; then
  for completion_file in $(brew --prefix)/etc/bash_completion.d/*; do
    source "$completion_file"
  done
fi
```

## Configuring Completions in `zsh`
To make Homebrew's completions available in `zsh`, you must get the Homebrew-managed zsh site-functions on your `FPATH` before initialising `zsh`'s completion facility. Add the following to your `~/.zshrc` file:

```sh
if type brew &>/dev/null; then
  FPATH=$(brew --prefix)/share/zsh/site-functions:$FPATH
fi
```

This must be done before `compinit` is called. Note that if you are using Oh My Zsh, it will call `compinit` for you, so this must be done before you call `oh-my-zsh.sh`.

You may also need to forcibly rebuild `zcompdump`:

```sh
  rm -f ~/.zcompdump; compinit
```

Additionally, if you receive "zsh compinit: insecure directories" warnings when attempting to load these completions, you may need to run this:

```sh
  chmod go-w "$(brew --prefix)/share"
```

## Configuring Completions in `fish`
No configuration is needed in `fish`. Friendly!
