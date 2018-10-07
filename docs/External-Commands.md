# External Commands

Homebrew, like Git, supports *external commands*. This lets you create new commands that can be run like:

```sh
brew mycommand --option1 --option3 <formula>
```

without modifying Homebrew's internals.

## Command types
External commands come in two flavours: Ruby commands and shell scripts.

In both cases, the command file should be executable (`chmod +x`) and live somewhere in `PATH`.

### Ruby commands
An external command `extcmd` implemented as a Ruby command should be named `brew-extcmd.rb`. The command is executed by doing a `require` on the full pathname. As the command is `require`d, it has full access to the Homebrew "environment", i.e. all global variables and modules that any internal command has access to. Be wary of using Homebrew internals; they may change at any time without warning.

The command may `Kernel.exit` with a status code if it needs to; if it doesn't explicitly exit then Homebrew will return `0`.

### Shell scripts
A shell script for a command named `extcmd` should be named `brew-extcmd`. This file will be run via `exec` with some Homebrew variables set as environment variables, and passed any additional command-line arguments.

| Variable               | Description                                                                                                                                                                 |
|------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `HOMEBREW_CACHE`       | Where Homebrew caches downloaded tarballs to, by default `~/Library/Caches/Homebrew`.                                                                                       |
| `HOMEBREW_CELLAR`      | The location of the Homebrew Cellar, where software is staged. This will be `HOMEBREW_PREFIX/Cellar` if that directory exists, or `HOMEBREW_REPOSITORY/Cellar` otherwise.   |
| `HOMEBREW_LIBRARY_PATH`| The directory containing Homebrew’s own application code.                                                                                                                   |
| `HOMEBREW_PREFIX`      | Where Homebrew installs software. This is always the grandparent directory of the `brew` executable, `/usr/local` by default.                                               |
| `HOMEBREW_REPOSITORY`  | If installed from a Git clone, the repository directory (i.e. where Homebrew’s `.git` directory lives).                                                                       |

Note that the script itself can use any suitable shebang (`#!`) line, so an external “shell script” can be written for sh, bash, Ruby, or anything else.

## Providing `--help`

All internal and external Homebrew commands can provide styled `--help` output by using lines starting with `#:` (a comment then `:` character in both Bash and Ruby) which are then output by `--help`.

For example, see the [header of `brew-services.rb`](https://github.com/Homebrew/homebrew-services/blob/a58a1fe9145de4e50e1cbfb5b0e8a30087826393/cmd/brew-services.rb#L1-L23) which is output with `brew services --help`.

## Homebrew organisation external commands

### homebrew-livecheck
Check if there is a new upstream version of a formula.
See the [`README`](https://github.com/Homebrew/homebrew-livecheck/blob/master/README.md) for more info and usage.

Install using:

```sh
brew tap homebrew/livecheck
```

### homebrew-command-not-found
Ubuntu's `command-not-found equivalent` for Homebrew.
See the [`README`](https://github.com/Homebrew/homebrew-command-not-found/blob/master/README.md) for more info and usage.

Install using:

```sh
brew tap homebrew/command-not-found
```

### homebrew-aliases
Allows you to alias your Homebrew commands.
See the [`README`](https://github.com/Homebrew/homebrew-aliases/blob/master/README.md) for more info and usage.

Install using:

```sh
brew tap homebrew/aliases
```

## Unofficial external commands
These commands have been contributed by Homebrew users but are not included in the main Homebrew organisation, nor are they installed by the installer script. You can install them manually, as outlined above.

Note they are largely untested, and as always, be careful about running untested code on your machine.

### brew-gem
Install any `gem` package into a self-contained Homebrew Cellar location: <https://github.com/sportngin/brew-gem>

Note this can also be installed with `brew install brew-gem`.
