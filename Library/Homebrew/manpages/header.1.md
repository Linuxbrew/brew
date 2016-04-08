brew(1) -- The missing package manager for OS X
===============================================

## SYNOPSIS

`brew` `--version`<br>
`brew` <command> [`--verbose`|`-v`] [<options>] [<formula>] ...

## DESCRIPTION

Homebrew is the easiest and most flexible way to install the UNIX tools Apple
didn't include with OS X.

## ESSENTIAL COMMANDS

For the full command list, see the [COMMANDS][] section.

With `--verbose` or `-v`, many commands print extra debugging information. Note that these flags should only appear after a command.

  * `install` <formula>:
    Install <formula>.

  * `remove` <formula>:
    Uninstall <formula>.

  * `update`:
    Fetch the newest version of Homebrew from GitHub using `git`(1).

  * `list`:
    List all installed formulae.

  * `search` <text>|`/`<text>`/`:
    Perform a substring search of formula names for <text>. If <text> is
    surrounded with slashes, then it is interpreted as a regular expression.
    The search for <text> is extended online to some popular taps.
    If no search term is given, all locally available formulae are listed.

## COMMANDS
