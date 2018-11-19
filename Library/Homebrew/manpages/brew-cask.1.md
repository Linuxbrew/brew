brew-cask(1) - a friendly binary installer for macOS
====================================================

## SYNOPSIS

`brew cask` command [options] [ <token> ... ]

## DESCRIPTION

Homebrew Cask is a tool for installing precompiled macOS binaries (such as
Applications) from the command line. The user is never required to use the
graphical user interface.

## FREQUENTLY USED COMMANDS

  * `install` [--force] [--skip-cask-deps] [--require-sha] [--no-quarantine] [--language=<iso-language>[,<iso-language> ... ]] <token> [ <token> ... ]:
    Install Cask identified by <token>.

  * `uninstall` [--force] <token> [ <token> ... ]:
    Uninstall Cask identified by <token>.

  * `search` <text> | /<regexp>/:
    Perform a substring search of known Cask tokens for <text>. If the text
    is delimited by slashes, it is interpreted as a Ruby regular expression.

    The tokens returned by `search` are suitable as arguments for most other
    commands, such as `install` or `uninstall`.

## COMMANDS

  * `audit` [--language=<iso-language>[,<iso-language> ... ]] [ <token> ... ]:
    Check the given Casks for installability.
    If no tokens are given on the command line, all Casks are audited.

  * `cat` <token> [ <token> ... ]:
    Dump the given Cask definition file to the standard output.

  * `cleanup` [--outdated]:
    Clean up cached downloads and tracker symlinks. With `--outdated`,
    only clean up cached downloads older than 10 days old.

  * `create` <token>:
    Generate a Cask definition file for the Cask identified by <token>
    and open a template for it in your favorite editor.

  * `doctor` or `dr`:
    Check for configuration issues. Can be useful to upload as a gist for
    developers along with a bug report.

  * `edit` <token>:
    Open the given Cask definition file for editing.

  * `fetch` [--force] [--no-quarantine] <token> [ <token> ... ]:
    Download remote application files for the given Cask to the local
    cache. With `--force`, force re-download even if the files are already
    cached. `--no-quarantine` will prevent Gatekeeper from
    enforcing its security restrictions on the Cask.

  * `home` or `homepage` [ <token> ... ]:
    Display the homepage associated with a given Cask in a browser.

    With no arguments, display the project page <https://caskroom.github.io/>.

  * `info` or `abv` <token> [ <token> ... ]:
    Display information about the given Cask.

  * `install` [--force] [--skip-cask-deps] [--require-sha] [--no-quarantine] <token> [ <token> ... ]:
    Install the given Cask. With `--force`, re-install even if the Cask
    appears to be already present. With `--skip-cask-deps`, skip any Cask
    dependencies. `--require-sha` will abort installation if the Cask does not
    have a checksum defined. `--no-quarantine` will prevent Gatekeeper from
    enforcing its security restrictions on the Cask.

    <token> is usually the ID of a Cask,
    but see [OTHER WAYS TO SPECIFY A CASK][] for variations.

  * `list` or `ls` [-1] [--versions] [ <token> ... ]:
    Without any arguments, list all installed Casks. With `-1`, always
    format the output in a single column. With `--versions`, show all installed
    versions.

    If <token> is given, summarize the staged files associated with the
    given Cask.

  * `outdated` [--greedy] [--verbose|--quiet] [ <token> ... ]:
    Without token arguments, display all the installed Casks that have newer
    versions available in the tap; otherwise check only the tokens given
    in the command line.
    If `--greedy` is given then also include in the output the Casks having
    `auto_updates true` or `version :latest`. Otherwise they are skipped
    because there is no reliable way to know when updates are available for
    them.<br>
    `--verbose` forces the display of the outdated and latest version.<br>
    `--quiet` suppresses the display of versions.

  * `reinstall` [--no-quarantine] <token> [ <token> ... ]:
    Reinstall the given Cask.

  * `search` or `-S` [<text> | /<regexp>/]:
    Without an argument, display all locally available Casks for install; no
    online search is performed.
    Otherwise perform a substring search of known Cask tokens for <text> or,
    if the text is delimited by slashes (/<regexp>/), it is interpreted as a
    Ruby regular expression.

  * `style` [--fix] [ <token> ... ]:
    Check the given Casks for correct style using RuboCop (with custom Cask cops).
    If no tokens are given on the command line, all Casks are checked.
    With `--fix`, auto-correct any style errors if possible.

  * `uninstall` or `rm` or `remove` [--force] <token> [ <token> ... ]:
    Uninstall the given Cask. With `--force`, uninstall even if the Cask
    does not appear to be present.

  * `upgrade` [--force] [--greedy] <token> [ <token> ... ]:
    Without token arguments, upgrade all the installed Casks that have newer
    versions available in the tap; otherwise update the tokens given
    in the command line.
    If `--greedy` is given then also upgrade the Casks having `auto_updates true`
    or `version :latest`.

  * `zap` [--force] <token> [ <token> ... ]:
    Unconditionally remove _all_ files associated with the given Cask.
    With `--force`, zap even if the Cask does not appear to be currently installed.

    Implicitly performs all actions associated with `uninstall`.

    Removes all staged versions of the Cask distribution found under
    `<Caskroom_path>/`<token>.

    If the Cask definition contains a `zap` stanza, performs additional
    `zap` actions as defined there, such as removing local preference
    files. `zap` actions are variable, depending on the level of detail
    defined by the Cask author.

    **`zap` may remove files which are shared between applications.**

## INTERNAL COMMANDS

  * `_stanza` <stanza_name> [ --table | --yaml | --inspect | --quiet ] [ <token> ... ]:
    Given a <stanza_name> and a <token>, returns the current stanza for a
    given Cask. If no <token> is given, then data for all Casks is returned.

## OPTIONS

To make these options persistent, see the [ENVIRONMENT](#environment) section, below.

Some of these (such as `--prefpanedir`) may be subject to removal
in a future version.

  * `--force`:
    Force an install to proceed even when a previously-existing install
    is detected.

  * `--skip-cask-deps`:
    Skip Cask dependencies when installing.

  *  `--require-sha`:
    Abort Cask installation if the Cask does not have a checksum defined.

  *  `--no-quarantine`:
    Prevent Gatekeeper from enforcing its security restrictions on the Cask.
    This will let you run it straightaway.

  * `--verbose`:
    Give additional feedback during installation.

  * `--appdir=<path>`:
    Target location for Applications. The default value is `/Applications`.

  * `--language=<iso-language>[,<iso-language> ... ]]`:
    Set language of the Cask to install. The first matching language is used, otherwise the default language on the Cask. The default value is the `language of your system`.

  * `--colorpickerdir=<path>`:
    Target location for Color Pickers. The default value is `~/Library/ColorPickers`.

  * `--prefpanedir=<path>`:
    Target location for Preference Panes. The default value is `~/Library/PreferencePanes`.

  * `--qlplugindir=<path>`:
    Target location for QuickLook Plugins. The default value is `~/Library/QuickLook`.

  * `--dictionarydir=<path>`:
    Target location for Dictionaries. The default value is `~/Library/Dictionaries`.

  * `--fontdir=<path>`:
    Target location for Fonts. The default value is `~/Library/Fonts`.

  * `--servicedir=<path>`:
    Target location for Services. The default value is `~/Library/Services`.

  * `--input_methoddir=<path>`:
    Target location for Input Methods. The default value is `~/Library/Input Methods`.

  * `--internet_plugindir=<path>`:
    Target location for Internet Plugins. The default value is `~/Library/Internet Plug-Ins`.

  * `--audio_unit_plugindir=<path>`:
    Target location for Audio Unit Plugins. The default value is `~/Library/Audio/Plug-Ins/Components`.

  * `--vst_plugindir=<path>`:
    Target location for VST Plugins. The default value is `~/Library/Audio/Plug-Ins/VST`.

  * `--vst3_plugindir=<path>`:
    Target location for VST3 Plugins. The default value is `~/Library/Audio/Plug-Ins/VST3`.

  * `--screen_saverdir=<path>`:
    Target location for Screen Savers. The default value is `~/Library/Screen Savers`.

  * `--no-binaries`:
    Do not link "helper" executables to `/usr/local/bin`.

  * `--debug`:
    Output debugging information of use to Cask authors and developers.

## INTERACTION WITH HOMEBREW

Homebrew Cask is implemented as a external command for Homebrew. That means
this project is entirely built upon the Homebrew infrastructure. For
example, upgrades to the Homebrew Cask tool are received through Homebrew:

    brew update; brew cask upgrade; brew cleanup

And updates to individual Cask definitions are received whenever you issue
the Homebrew command:

    brew update

## OTHER WAYS TO SPECIFY A CASK

Most Homebrew Cask commands can accept a Cask token as an argument. As
described above, the argument can take the form of:

  * A simple token, e.g. `google-chrome`

Homebrew Cask also accepts three other forms in place of plain tokens:

  * A fully-qualified token which includes the Tap name, e.g.
    `homebrew/cask-fonts/font-symbola`

  * A fully-qualified pathname to a Cask file, e.g.
    `/usr/local/Library/Taps/homebrew/homebrew-cask/Casks/google-chrome.rb`

  * A `curl`-retrievable URI to a Cask file, e.g.
    `https://raw.githubusercontent.com/Homebrew/homebrew-cask/f25b6babcd398abf48e33af3d887b2d00de1d661/Casks/google-chrome.rb`

## ENVIRONMENT

Homebrew Cask respects many of the environment variables used by the
parent command `brew`. Please refer to the `brew`(1) man page for more
information.

Environment variables specific to Homebrew Cask:

  * `HOMEBREW_CASK_OPTS`:
    This variable may contain any arguments normally used as options on
    the command-line. This is particularly useful to make options persistent.
    For example, you might add to your .bash_profile or .zshenv something like:

               export HOMEBREW_CASK_OPTS='--appdir=~/Applications --fontdir=/Library/Fonts'

Other environment variables:

  * `SUDO_ASKPASS`:
    When this variable is set, Homebrew Cask will call `sudo`(8) with the `-A` option.


## SEE ALSO

The Homebrew Cask home page: <https://caskroom.github.io/>

The Homebrew Cask GitHub page: <https://github.com/Homebrew/homebrew-cask>

`brew`(1), `curl`(1)

## AUTHORS

Paul Hinze and Contributors.

Man page format based on `brew.1.md` from Homebrew.

## BUGS

We still have bugs - and we are busy fixing them!  If you have a problem, don't
be shy about reporting it on our [GitHub issues page](https://github.com/Homebrew/homebrew-cask/issues?state=open).

When reporting bugs, remember that Homebrew Cask is an separate repository within
Homebrew. Do your best to direct bug reports to the appropriate repository. If
your command-line started with `brew cask`, bring the bug to us first!
