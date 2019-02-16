brew(1) -- The missing package manager for macOS
================================================

## SYNOPSIS

`brew` `--version`<br>
`brew` *`command`* [`--verbose`|`-v`] [*`options`*] [*`formula`*] ...

## DESCRIPTION

Homebrew is the easiest and most flexible way to install the UNIX tools Apple
didn't include with macOS.

## ESSENTIAL COMMANDS

For the full command list, see the [COMMANDS](#commands) section.

With `--verbose` or `-v`, many commands print extra debugging information. Note that
these flags should only appear after a command.

  * `install` *`formula`*:
    Install *`formula`*.

  * `uninstall` *`formula`*:
    Uninstall *`formula`*.

  * `update`:
    Fetch the newest version of Homebrew from GitHub using `git`(1).

  * `list`:
    List all installed formulae.

  * `search` (*`text`*|`/`*`text`*`/`):
    Perform a substring search of cask tokens and formula names for *`text`*. If *`text`*
    is surrounded with slashes, then it is interpreted as a regular expression.
    The search for *`text`* is extended online to `homebrew/core` and `homebrew/cask`.
    If no search term is given, all locally available formulae are listed.

## COMMANDS

  * `analytics` [`state`]:
    Display anonymous user behaviour analytics state.
    Read more at <https://docs.brew.sh/Analytics>.

  * `analytics` (`on`|`off`):
    Turn on/off Homebrew's analytics.

  * `analytics` `regenerate-uuid`:
    Regenerate UUID used in Homebrew's analytics.

  * `cat` *`formula`*:
    Display the source to *`formula`*.

  * `cleanup` [`--prune=`*`days`*] [`--dry-run`] [`-s`] [*`formulae`*|*`casks`*]:
    Remove stale lock files and outdated downloads for formulae and casks,
    and remove old versions of installed formulae. If arguments are specified,
    only do this for the specified formulae and casks.

    If `--prune=`*`days`* is specified, remove all cache files older than *`days`*.

    If `--dry-run` or `-n` is passed, show what would be removed, but do not
    actually remove anything.

    If `-s` is passed, scrub the cache, including downloads for even the latest
    versions. Note downloads for any installed formula or cask will still not
    be deleted. If you want to delete those too: `rm -rf "$(brew --cache)"`

  * `command` *`cmd`*:
    Display the path to the file which is used when invoking `brew` *`cmd`*.

  * `commands` [`--quiet` [`--include-aliases`]]:
    Show a list of built-in and external commands.

    If `--quiet` is passed, list only the names of commands without the header.
    With `--include-aliases`, the aliases of internal commands will be included.

  * `config`:
    Show Homebrew and system configuration useful for debugging. If you file
    a bug report, you will likely be asked for this information if you do not
    provide it.

  * `configure-shell`:
    Configure the shell to include Homebrew into your PATH, MANPATH, and INFOPATH.
    A brew.env file will be created that will be sourced in your ~/.profile
    (or your .bash_profile or .zprofile - only existing files will be modified)

  * `deps` [`--1`] [`-n`] [`--union`] [`--full-name`] [`--installed`] [`--include-build`] [`--include-optional`] [`--skip-recommended`] [`--include-requirements`] *`formulae`*:
    Show dependencies for *`formulae`*. When given multiple formula arguments,
    show the intersection of dependencies for *`formulae`*.

    If `--1` is passed, only show dependencies one level down, instead of
    recursing.

    If `-n` is passed, show dependencies in topological order.

    If `--union` is passed, show the union of dependencies for *`formulae`*,
    instead of the intersection.

    If `--full-name` is passed, list dependencies by their full name.

    If `--installed` is passed, only list those dependencies that are
    currently installed.

    By default, `deps` shows required and recommended dependencies for
    *`formulae`*. To include the `:build` type dependencies, pass `--include-build`.
    Similarly, pass `--include-optional` to include `:optional` dependencies or
    `--include-test` to include (non-recursive) `:test` dependencies.
    To skip `:recommended` type dependencies, pass `--skip-recommended`.
    To include requirements in addition to dependencies, pass `--include-requirements`.

  * `deps` `--tree` [`--1`] [*`filters`*] [`--annotate`] (*`formulae`*|`--installed`):
    Show dependencies as a tree. When given multiple formula arguments, output
    individual trees for every formula.

    If `--1` is passed, only one level of children is displayed.

    If `--installed` is passed, output a tree for every installed formula.

    The *`filters`* placeholder is any combination of options `--include-build`,
    `--include-optional`, `--include-test`, `--skip-recommended`, and
    `--include-requirements` as documented above.

    If `--annotate` is passed, the build, optional, and recommended dependencies
    are marked as such in the output.

  * `deps` [*`filters`*] (`--installed`|`--all`):
    Show dependencies for installed or all available formulae. Every line of
    output starts with the formula name, followed by a colon and all direct
    dependencies of that formula.

    The *`filters`* placeholder is any combination of options `--include-build`,
    `--include-optional`, `--include-test`, and `--skip-recommended` as
    documented above.

  * `desc` *`formula`*:
    Display *`formula`*'s name and one-line description.

  * `desc` [`--search`|`--name`|`--description`] (*`text`*|`/`*`text`*`/`):
    Search both name and description (`--search` or `-s`), just the names
    (`--name` or `-n`), or just the descriptions (`--description` or `-d`) for
    *`text`*. If *`text`* is flanked by slashes, it is interpreted as a regular
    expression. Formula descriptions are cached; the cache is created on the
    first search, making that search slower than subsequent ones.

  * `diy` [`--name=`*`name`*] [`--version=`*`version`*]:
    Automatically determine the installation prefix for non-Homebrew software.

    Using the output from this command, you can install your own software into
    the Cellar and then link it into Homebrew's prefix with `brew link`.

    The options `--name=`*`name`* and `--version=`*`version`* each take an argument
    and allow you to explicitly set the name and version of the package you are
    installing.

  * `doctor`:
    Check your system for potential problems. Doctor exits with a non-zero status
    if any potential problems are found. Please note that these warnings are just
    used to help the Homebrew maintainers with debugging if you file an issue. If
    everything you use Homebrew for is working fine: please don't worry or file
    an issue; just ignore this.

  * `fetch` [`--force`] [`--retry`] [`-v`] [`--devel`|`--HEAD`] [`--deps`] [`--build-from-source`|`--force-bottle`] *`formulae`*:
    Download the source packages for the given *`formulae`*.
    For tarballs, also print SHA-256 checksums.

    If `--HEAD` or `--devel` is passed, fetch that version instead of the
    stable version.

    If `-v` is passed, do a verbose VCS checkout, if the URL represents a VCS.
    This is useful for seeing if an existing VCS cache has been updated.

    If `--force` (or `-f`) is passed, remove a previously cached version and re-fetch.

    If `--retry` is passed, retry if a download fails or re-download if the
    checksum of a previously cached version no longer matches.

    If `--deps` is passed, also download dependencies for any listed *`formulae`*.

    If `--build-from-source` (or `-s`) is passed, download the source rather than a
    bottle.

    If `--force-bottle` is passed, download a bottle if it exists for the
    current or newest version of macOS, even if it would not be used during
    installation.

  * `gist-logs` [`--new-issue`|`-n`] [`--private`|`-p`] *`formula`*:
    Upload logs for a failed build of *`formula`* to a new Gist.

    *`formula`* is usually the name of the formula to install, but it can be specified
    in several different ways. See [SPECIFYING FORMULAE](#specifying-formulae).

    If `--with-hostname` is passed, include the hostname in the Gist.

    If `--new-issue` is passed, automatically create a new issue in the appropriate
    GitHub repository as well as creating the Gist.

    If `--private` is passed, the Gist will be marked private and will not
    appear in listings but will be accessible with the link.

    If no logs are found, an error message is presented.

  * `home`:
    Open Homebrew's own homepage in a browser.

  * `home` *`formula`*:
    Open *`formula`*'s homepage in a browser.

  * `info`:
    Display brief statistics for your Homebrew installation.

  * `info` `--analytics` [`--days=`*`days`*] [`--category=`*`category`*]:
    Display Homebrew analytics data (provided neither `HOMEBREW_NO_ANALYTICS`
    or `HOMEBREW_NO_GITHUB_API` are set)

    The value for `days` must be `30`, `90` or `365`. The default is `30`.

    The value for `category` must be `install`, `install-on-request`,
    `build-error` or `os-version`. The default is `install`.

  * `info` *`formula`* [`--analytics`]:
    Display information about *`formula`* and analytics data (provided neither
    `HOMEBREW_NO_ANALYTICS` or `HOMEBREW_NO_GITHUB_API` are set)

    Pass `--verbose` to see more verbose analytics data.

    Pass `--analytics` to see only more verbose analytics data instead of
    formula information.

  * `info` `--github` *`formula`*:
    Open a browser to the GitHub History page for *`formula`*.

    To view formula history locally: `brew log -p` *`formula`*

  * `info` `--json[=`*`version`*] (`--all`|`--installed`|*`formulae`*):
    Print a JSON representation of *`formulae`*. Currently the default and
    only accepted value for *`version`* is `v1`.

    Pass `--all` to get information on all formulae, or `--installed` to get
    information on all installed formulae.

    See the docs for examples of using the JSON output:
    <https://docs.brew.sh/Querying-Brew>

  * `install` [`--debug`] [`--env=`(`std`|`super`)] [`--ignore-dependencies`|`--only-dependencies`] [`--cc=`*`compiler`*] [`--build-from-source`|`--force-bottle`] [`--include-test`] [`--devel`|`--HEAD`] [`--keep-tmp`] [`--build-bottle`] [`--force`] [`--verbose`] [`--display-times`] *`formula`* [*`options`* ...]:
    Install *`formula`*.

    *`formula`* is usually the name of the formula to install, but it can be specified
    in several different ways. See [SPECIFYING FORMULAE](#specifying-formulae).

    If `--debug` (or `-d`) is passed and brewing fails, open an interactive debugging
    session with access to IRB or a shell inside the temporary build directory.

    If `--env=std` is passed, use the standard build environment instead of superenv.

    If `--env=super` is passed, use superenv even if the formula specifies the
    standard build environment.

    If `--ignore-dependencies` is passed, skip installing any dependencies of
    any kind. If they are not already present, the formula will probably fail
    to install.

    If `--only-dependencies` is passed, install the dependencies with specified
    options but do not install the specified formula.

    If `--cc=`*`compiler`* is passed, attempt to compile using *`compiler`*.
    *`compiler`* should be the name of the compiler's executable, for instance
    `gcc-7` for GCC 7. In order to use LLVM's clang, use `llvm_clang`.
    To specify the Apple-provided clang, use `clang`.
    This parameter will only accept compilers that are provided by Homebrew or
    bundled with macOS. Please do not file issues if you encounter errors
    while using this flag.

    If `--build-from-source` (or `-s`) is passed, compile the specified *`formula`* from
    source even if a bottle is provided. Dependencies will still be installed
    from bottles if they are available.

    If `HOMEBREW_BUILD_FROM_SOURCE` is set, regardless of whether `--build-from-source` was
    passed, then both *`formula`* and the dependencies installed as part of this process
    are built from source even if bottles are available.

    If `--force-bottle` is passed, install from a bottle if it exists for the
    current or newest version of macOS, even if it would not normally be used
    for installation.

    If `--include-test` is passed, install testing dependencies. These are only
    needed by formulae maintainers to run `brew test`.

    If `--devel` is passed, and *`formula`* defines it, install the development version.

    If `--HEAD` is passed, and *`formula`* defines it, install the HEAD version,
    aka master, trunk, unstable.

    If `--keep-tmp` is passed, the temporary files created during installation
    are not deleted.

    If `--build-bottle` is passed, prepare the formula for eventual bottling
    during installation.

    If `--force` (or `-f`) is passed, install without checking for previously
    installed keg-only or non-migrated versions

    If `--verbose` (or `-v`) is passed, print the verification and postinstall steps.

    If `--display-times` is passed, install times for each formula are printed
    at the end of the run.

    Installation options specific to *`formula`* may be appended to the command,
    and can be listed with `brew options` *`formula`*.

  * `install` `--interactive` [`--git`] *`formula`*:
    If `--interactive` (or `-i`) is passed, download and patch *`formula`*, then
    open a shell. This allows the user to run `./configure --help` and
    otherwise determine how to turn the software package into a Homebrew
    formula.

    If `--git` (or `-g`) is passed, Homebrew will create a Git repository, useful for
    creating patches to the software.

  * `leaves`:
    Show installed formulae that are not dependencies of another installed formula.

  * `ln`, `link` [`--overwrite`] [`--dry-run`] [`--force`] *`formula`*:
    Symlink all of *`formula`*'s installed files into the Homebrew prefix. This
    is done automatically when you install formulae but can be useful for DIY
    installations.

    If `--overwrite` is passed, Homebrew will delete files which already exist in
    the prefix while linking.

    If `--dry-run` or `-n` is passed, Homebrew will list all files which would
    be linked or which would be deleted by `brew link --overwrite`, but will not
    actually link or delete any files.

    If `--force` (or `-f`) is passed, Homebrew will allow keg-only formulae to be linked.

  * `list`, `ls` [`--full-name`] [`-1`] [`-l`] [`-t`] [`-r`]:
    List all installed formulae. If `--full-name` is passed, print formulae
    with fully-qualified names. If `--full-name` is not passed, other
    options (i.e. `-1`, `-l`, `-t` and `-r`) are passed to `ls` which produces the actual output.

  * `list`, `ls` `--unbrewed`:
    List all files in the Homebrew prefix not installed by Homebrew.

  * `list`, `ls` [`--verbose`] [`--versions` [`--multiple`]] [`--pinned`] [*`formulae`*]:
    List the installed files for *`formulae`*. Combined with `--verbose`, recursively
    list the contents of all subdirectories in each *`formula`*'s keg.

    If `--versions` is passed, show the version number for installed formulae,
    or only the specified formulae if *`formulae`* are given. With `--multiple`,
    only show formulae with multiple versions installed.

    If `--pinned` is passed, show the versions of pinned formulae, or only the
    specified (pinned) formulae if *`formulae`* are given.
    See also `pin`, `unpin`.

  * `log` [*`git-log-options`*] *`formula`* ...:
    Show the git log for the given formulae. Options that `git-log`(1)
    recognizes can be passed before the formula list.

  * `migrate` [`--force`] *`formulae`*:
    Migrate renamed packages to new name, where *`formulae`* are old names of
    packages.

    If `--force` (or `-f`) is passed, then treat installed *`formulae`* and passed *`formulae`*
    like if they are from same taps and migrate them anyway.

  * `missing` [`--hide=`*`hidden`*] [*`formulae`*]:
    Check the given *`formulae`* for missing dependencies. If no *`formulae`* are
    given, check all installed brews.

    If `--hide=`*`hidden`* is passed, act as if none of *`hidden`* are installed.
    *`hidden`* should be a comma-separated list of formulae.

    `missing` exits with a non-zero status if any formulae are missing dependencies.

  * `options` [`--compact`] (`--all`|`--installed`|*`formulae`*):
    Display install options specific to *`formulae`*.

    If `--compact` is passed, show all options on a single line separated by
    spaces.

    If `--all` is passed, show options for all formulae.

    If `--installed` is passed, show options for all installed formulae.

  * `outdated` [`--quiet`|`--verbose`|`--json=`*`version`*] [`--fetch-HEAD`]:
    Show formulae that have an updated version available.

    By default, version information is displayed in interactive shells, and
    suppressed otherwise.

    If `--quiet` is passed, list only the names of outdated brews (takes
    precedence over `--verbose`).

    If `--verbose` (or `-v`) is passed, display detailed version information.

    If `--json=`*`version`* is passed, the output will be in JSON format.
    Currently the only accepted value for *`version`* is `v1`.

    If `--fetch-HEAD` is passed, fetch the upstream repository to detect if
    the HEAD installation of the formula is outdated. Otherwise, the
    repository's HEAD will be checked for updates when a new stable or devel
    version has been released.

  * `pin` *`formulae`*:
    Pin the specified *`formulae`*, preventing them from being upgraded when
    issuing the `brew upgrade` *`formulae`* command. See also `unpin`.

  * `postinstall` *`formula`*:
    Rerun the post-install steps for *`formula`*.

  * `prune` [`--dry-run`]:
    Deprecated. Use `brew cleanup` instead.

  * `readall` [`--aliases`] [`--syntax`] [*`taps`*]:
    Import all formulae from specified *`taps`* (defaults to all installed taps).

    This can be useful for debugging issues across all formulae when making
    significant changes to `formula.rb`, testing the performance of loading
    all formulae or to determine if any current formulae have Ruby issues.

    If `--aliases` is passed, also verify any alias symlinks in each tap.

    If `--syntax` is passed, also syntax-check all of Homebrew's Ruby files.

  * `reinstall` [`--display-times`] *`formula`*:
    Uninstall and then install *`formula`* (with existing install options).

    If `--display-times` is passed, install times for each formula are printed
    at the end of the run.

    If `HOMEBREW_INSTALL_CLEANUP` is set then remove previously installed versions
    of upgraded *`formulae`* as well as the HOMEBREW_CACHE for that formula.

  * `search`, `-S`:
    Display all locally available formulae (including tapped ones).
    No online search is performed.

  * `search` `--casks`:
    Display all locally available casks (including tapped ones).
    No online search is performed.

  * `search` [`--desc`] (*`text`*|`/`*`text`*`/`):
    Perform a substring search of cask tokens and formula names for *`text`*. If *`text`*
    is surrounded with slashes, then it is interpreted as a regular expression.
    The search for *`text`* is extended online to `homebrew/core` and `homebrew/cask`.

    If `--desc` is passed, search formulae with a description matching *`text`* and
    casks with a name matching *`text`*.

  * `search` (`--debian`|`--fedora`|`--fink`|`--macports`|`--opensuse`|`--ubuntu`) *`text`*:
    Search for *`text`* in the given package manager's list.

  * `sh` [`--env=std`]:
    Start a Homebrew build environment shell. Uses our years-battle-hardened
    Homebrew build logic to help your `./configure && make && make install`
    or even your `gem install` succeed. Especially handy if you run Homebrew
    in an Xcode-only configuration since it adds tools like `make` to your `PATH`
    which otherwise build systems would not find.

    If `--env=std` is passed, use the standard `PATH` instead of superenv's.

  * `shellenv`:
    Prints export statements - run them in a shell and this installation of
    Homebrew will be included into your PATH, MANPATH, and INFOPATH.

    HOMEBREW_PREFIX, HOMEBREW_CELLAR and HOMEBREW_REPOSITORY are also exported
    to save multiple queries of those variables.

    Consider adding evaluating the output in your dotfiles (e.g. `~/.profile`)
    with `eval $(brew shellenv)`

  * `style` [`--fix`] [`--display-cop-names`] [`--only-cops=`*`cops`*|`--except-cops=`*`cops`*] [*`files`*|*`taps`*|*`formulae`*]:
    Check formulae or files for conformance to Homebrew style guidelines.

    Lists of *`files`*, *`taps`* and *`formulae`* may not be combined. If none are
    provided, `style` will run style checks on the whole Homebrew library,
    including core code and all formulae.

    If `--fix` is passed, automatically fix style violations using RuboCop's
    auto-correct feature.

    If `--display-cop-names` is passed, include the RuboCop cop name for each
    violation in the output.

    Passing `--only-cops=`*`cops`* will check for violations of only the listed
    RuboCop *`cops`*, while `--except-cops=`*`cops`* will skip checking the listed
    *`cops`*. For either option *`cops`* should be a comma-separated list of cop names.

    Exits with a non-zero status if any style violations are found.

  * `switch` *`formula`* *`version`*:
    Symlink all of the specific *`version`* of *`formula`*'s install to Homebrew prefix.

  * `tap`:
    List all installed taps.

  * `tap` [`--full`] [`--force-auto-update`] *`user`*`/`*`repo`* [*`URL`*]:
    Tap a formula repository.

    With *`URL`* unspecified, taps a formula repository from GitHub using HTTPS.
    Since so many taps are hosted on GitHub, this command is a shortcut for
    `brew tap` *`user`*`/`*`repo`* `https://github.com/`*`user`*`/homebrew-`*`repo`*.

    With *`URL`* specified, taps a formula repository from anywhere, using
    any transport protocol that `git` handles. The one-argument form of `tap`
    simplifies but also limits. This two-argument command makes no
    assumptions, so taps can be cloned from places other than GitHub and
    using protocols other than HTTPS, e.g., SSH, GIT, HTTP, FTP(S), RSYNC.

    By default, the repository is cloned as a shallow copy (`--depth=1`), but
    if `--full` is passed, a full clone will be used. To convert a shallow copy
    to a full copy, you can retap passing `--full` without first untapping.

    By default, only taps hosted on GitHub are auto-updated (for performance
    reasons). If `--force-auto-update` is passed, this tap will be auto-updated
    even if it is not hosted on GitHub.

    `tap` is re-runnable and exits successfully if there's nothing to do.
    However, retapping with a different *`URL`* will cause an exception, so first
    `untap` if you need to modify the *`URL`*.

  * `tap` `--repair`:
    Migrate tapped formulae from symlink-based to directory-based structure.

  * `tap` `--list-pinned`:
    List all pinned taps.

  * `tap-info`:
    Display a brief summary of all installed taps.

  * `tap-info` (`--installed`|*`taps`*):
    Display detailed information about one or more *`taps`*.

    Pass `--installed` to display information on all installed taps.

  * `tap-info` `--json=`*`version`* (`--installed`|*`taps`*):
    Print a JSON representation of *`taps`*. Currently the only accepted value
    for *`version`* is `v1`.

    Pass `--installed` to get information on installed taps.

    See the docs for examples of using the JSON output:
    <https://docs.brew.sh/Querying-Brew>

  * `tap-pin` *`tap`*:
    Pin *`tap`*, prioritizing its formulae over core when formula names are supplied
    by the user. See also `tap-unpin`.

  * `tap-unpin` *`tap`*:
    Unpin *`tap`* so its formulae are no longer prioritized. See also `tap-pin`.

  * `uninstall`, `rm`, `remove` [`--force`] [`--ignore-dependencies`] *`formula`*:
    Uninstall *`formula`*.

    If `--force` (or `-f`) is passed, and there are multiple versions of *`formula`*
    installed, delete all installed versions.

    If `--ignore-dependencies` is passed, uninstalling won't fail, even if
    formulae depending on *`formula`* would still be installed.

  * `unlink` [`--dry-run`] *`formula`*:
    Remove symlinks for *`formula`* from the Homebrew prefix. This can be useful
    for temporarily disabling a formula:
    `brew unlink` *`formula`* `&&` *`commands`* `&& brew link` *`formula`*

    If `--dry-run` or `-n` is passed, Homebrew will list all files which would
    be unlinked, but will not actually unlink or delete any files.

  * `unpack` [`--git`|`--patch`] [`--destdir=`*`path`*] *`formulae`*:
    Unpack the source files for *`formulae`* into subdirectories of the current
    working directory. If `--destdir=`*`path`* is given, the subdirectories will
    be created in the directory named by *`path`* instead.

    If `--patch` is passed, patches for *`formulae`* will be applied to the
    unpacked source.

    If `--git` (or `-g`) is passed, a Git repository will be initialized in the unpacked
    source. This is useful for creating patches for the software.

  * `unpin` *`formulae`*:
    Unpin *`formulae`*, allowing them to be upgraded by `brew upgrade` *`formulae`*.
    See also `pin`.

  * `untap` *`tap`*:
    Remove a tapped repository.

  * `update` [`--merge`] [`--force`]:
    Fetch the newest version of Homebrew and all formulae from GitHub using
    `git`(1) and perform any necessary migrations.

    If `--merge` is specified then `git merge` is used to include updates
    (rather than `git rebase`).

    If `--force` (or `-f`) is specified then always do a slower, full update check even
    if unnecessary.

  * `update-reset` [*`repositories`*]:
    Fetches and resets Homebrew and all tap repositories (or the specified
    `repositories`) using `git`(1) to their latest `origin/master`. Note this
    will destroy all your uncommitted or committed changes.

  * `upgrade` [*`install-options`*] [`--fetch-HEAD`] [`--ignore-pinned`] [`--display-times`] [*`formulae`*]:
    Upgrade outdated, unpinned brews (with existing install options).

    Options for the `install` command are also valid here.

    If `--fetch-HEAD` is passed, fetch the upstream repository to detect if
    the HEAD installation of the formula is outdated. Otherwise, the
    repository's HEAD will be checked for updates when a new stable or devel
    version has been released.

    If `--ignore-pinned` is passed, set a 0 exit code even if pinned formulae
    are not upgraded.

    If `--display-times` is passed, install times for each formula are printed
    at the end of the run.

    If *`formulae`* are given, upgrade only the specified brews (unless they
    are pinned; see `pin`, `unpin`).

  * `uses` [`--installed`] [`--recursive`] [`--include-build`] [`--include-test`] [`--include-optional`] [`--skip-recommended`] [`--devel`|`--HEAD`] *`formulae`*:
    Show the formulae that specify *`formulae`* as a dependency. When given
    multiple formula arguments, show the intersection of formulae that use
    *`formulae`*.

    Use `--recursive` to resolve more than one level of dependencies.

    If `--installed` is passed, only list installed formulae.

    By default, `uses` shows all formulae that specify *`formulae`* as a required
    or recommended dependency. To include the `:build` type dependencies, pass
    `--include-build`, to include the `:test` type dependencies, pass
    `--include-test` and to include `:optional` dependencies pass
    `--include-optional`. To skip `:recommended` type dependencies, pass
    `--skip-recommended`.

    By default, `uses` shows usage of *`formulae`* by stable builds. To find
    cases where *`formulae`* is used by development or HEAD build, pass
    `--devel` or `--HEAD`.

  * `--cache`:
    Display Homebrew's download cache. See also `HOMEBREW_CACHE`.

  * `--cache` [`--build-from-source`|`-s`] [`--force-bottle`] *`formula`*:
    Display the file or directory used to cache *`formula`*.

  * `--cellar`:
    Display Homebrew's Cellar path. *Default:* `$(brew --prefix)/Cellar`, or if
    that directory doesn't exist, `$(brew --repository)/Cellar`.

  * `--cellar` *`formula`*:
    Display the location in the cellar where *`formula`* would be installed,
    without any sort of versioned directory as the last path.

  * `--env` [`--shell=`(*`shell`*|`auto`)|`--plain`]:
    Show a summary of the Homebrew build environment as a plain list.

    Pass `--shell=`*`shell`* to generate a list of environment variables for the
    specified shell, or `--shell=auto` to detect the current shell.

    If the command's output is sent through a pipe and no shell is specified,
    the list is formatted for export to `bash`(1) unless `--plain` is passed.

  * `--prefix`:
    Display Homebrew's install path. *Default:* `/usr/local` on macOS and `/home/linuxbrew/.linuxbrew` on Linux

  * `--prefix` *`formula`*:
    Display the location in the cellar where *`formula`* is or would be installed.

  * `--repository`:
    Display where Homebrew's `.git` directory is located.

  * `--repository` *`user`*`/`*`repo`*:
    Display where tap *`user`*`/`*`repo`*'s directory is located.

  * `--version`:
    Print the version number of Homebrew to standard output and exit.

## DEVELOPER COMMANDS

### `audit` [*`options`*] *`formulae`*

Check *`formulae`* for Homebrew coding style violations. This should be run before
submitting a new formula. Will exit with a non-zero status if any errors are
found, which can be useful for implementing pre-commit hooks.
If no *`formulae`* are provided, all of them are checked.

* `--strict`:
  Run additional style checks, including RuboCop style checks.
* `--online`:
  Run additional slower style checks that require a network connection.
* `--new-formula`:
  Run various additional style checks to determine if a new formula is eligible for Homebrew. This should be used when creating new formula and implies `--strict` and `--online`.
* `--fix`:
  Fix style violations automatically using RuboCop's auto-correct feature.
* `--display-cop-names`:
  Include the RuboCop cop name for each violation in the output.
* `--display-filename`:
  Prefix every line of output with name of the file or formula being audited, to make output easy to grep.
* `-D`, `--audit-debug`:
  Enable debugging and profiling of audit methods.
* `--only`:
  Specify a comma-separated *`method`* list to only run the methods named `audit_`*`method`*.
* `--except`:
  Specify a comma-separated *`method`* list to skip running the methods named `audit_`*`method`*.
* `--only-cops`:
  Specify a comma-separated *`cops`* list to check for violations of only the listed RuboCop cops.
* `--except-cops`:
  Specify a comma-separated *`cops`* list to skip checking for violations of the listed RuboCop cops.

### `bottle` [*`options`*] *`formulae`*

Generate a bottle (binary package) from a formula that was installed with
`--build-bottle`.
If the formula specifies a rebuild version, it will be incremented in the
generated DSL. Passing `--keep-old` will attempt to keep it at its original
value, while `--no-rebuild` will remove it.

* `--skip-relocation`:
  Do not check if the bottle can be marked as relocatable.
* `--or-later`:
  Append `_or_later` to the bottle tag.
* `--force-core-tap`:
  Build a bottle even if *`formula`* is not in homebrew/core or any installed taps.
* `--no-rebuild`:
  If the formula specifies a rebuild version, remove it from the generated DSL.
* `--keep-old`:
  If the formula specifies a rebuild version, attempt to preserve its value in the generated DSL.
* `--json`:
  Write bottle information to a JSON file, which can be used as the argument for `--merge`.
* `--merge`:
  Generate an updated bottle block for a formula and optionally merge it into the formula file. Instead of a formula name, requires a JSON file generated with `brew bottle --json` *`formula`*.
* `--write`:
  Write the changes to the formula file. A new commit will be generated unless `--no-commit` is passed.
* `--no-commit`:
  When passed with `--write`, a new commit will not generated after writing changes to the formula file.
* `--root-url`:
  Use the specified *`URL`* as the root of the bottle's URL instead of Homebrew's default.

### `bump-formula-pr` [*`options`*] [*`formula`*]

Create a pull request to update a formula with a new URL or a new tag.

If a *`URL`* is specified, the *`SHA-256`* checksum of the new download should also
be specified. A best effort to determine the *`SHA-256`* and *`formula`* name will
be made if either or both values are not supplied by the user.

If a *`tag`* is specified, the Git commit *`revision`* corresponding to that tag
must also be specified.

*Note:* this command cannot be used to transition a formula from a
URL-and-SHA-256 style specification into a tag-and-revision style specification,
nor vice versa. It must use whichever style specification the preexisting
formula already uses.

* `--devel`:
  Bump the development rather than stable version. The development spec must already exist.
* `-n`, `--dry-run`:
  Print what would be done rather than doing it.
* `--write`:
  When passed along with `--dry-run`, perform a not-so-dry run by making the expected file modifications but not taking any Git actions.
* `--no-audit`:
  Don't run `brew audit` before opening the PR.
* `--strict`:
  Run `brew audit --strict` before opening the PR.
* `--no-browse`:
  Print the pull request URL instead of opening in a browser.
* `--mirror`:
  Use the provided *`URL`* as a mirror URL.
* `--version`:
  Use the provided *`version`* to override the value parsed from the URL or tag. Note that `--version=0` can be used to delete an existing version override from a formula if it has become redundant.
* `--message`:
  Append the provided *`message`* to the default PR message.
* `--url`:
  Specify the *`URL`* for the new download. If a *`URL`* is specified, the *`SHA-256`* checksum of the new download should also be specified.
* `--sha256`:
  Specify the *`SHA-256`* checksum of the new download.
* `--tag`:
  Specify the new git commit *`tag`* for the formula.
* `--revision`:
  Specify the new git commit *`revision`* corresponding to a specified *`tag`*.

### `create` [*`options`*] *`URL`*

Generate a formula for the downloadable file at *`URL`* and open it in the editor.
Homebrew will attempt to automatically derive the formula name and version, but
if it fails, you'll have to make your own template. The `wget` formula serves as
a simple example. For the complete API, see:
<http://www.rubydoc.info/github/Homebrew/brew/master/Formula>

* `--autotools`:
  Create a basic template for an Autotools-style build.
* `--cmake`:
  Create a basic template for a CMake-style build.
* `--meson`:
  Create a basic template for a Meson-style build.
* `--no-fetch`:
  Homebrew will not download *`URL`* to the cache and will thus not add the SHA-256 to the formula for you, nor will it check the GitHub API for GitHub projects (to fill out its description and homepage).
* `--HEAD`:
  Indicate that *`URL`* points to the package's repository rather than a file.
* `--set-name`:
  Set the name of the new formula to the provided *`name`*.
* `--set-version`:
  Set the version of the new formula to the provided *`version`*.
* `--tap`:
  Generate the new formula in the provided tap, specified as *`user`*`/`*`repo`*.

### `edit` [*`formulae`*]

Open a formula in the editor set by `EDITOR` or `HOMEBREW_EDITOR`, or open the
Homebrew repository for editing if no *`formula`* is provided.


### `extract` [*`options`*] *`formula`* *`tap`*

Look through repository history to find the most recent version of *`formula`* and
create a copy in *`tap`*`/Formula/`*`formula`*`@`*`version`*`.rb`. If the tap is not
installed yet, attempt to install/clone the tap before continuing.

* `--version`:
  Extract the provided *`version`* of *`formula`* instead of the most recent.

### `formula` *`formulae`*

Display the path where a formula is located.


### `irb` [*`options`*]

Enter the interactive Homebrew Ruby shell.

* `--examples`:
  Show several examples.
* `--pry`:
  Use Pry instead of IRB. Implied if `HOMEBREW_PRY` is set.

### `linkage` [*`options`*] [*`formulae`*]

Check the library links for kegs of installed formulae.
Raises an error if run on uninstalled formulae.

* `--test`:
  Display only missing libraries and exit with a non-zero status if any missing libraries are found.
* `--reverse`:
  For every library that a keg references, print its dylib path followed by the binaries that link to it.
* `--cached`:
  Print the cached linkage values stored in `HOMEBREW_CACHE`, set by a previous `brew linkage` run.

### `man` [*`options`*]

Generate Homebrew's manpages.

* `--fail-if-changed`:
  Return a failing status code if changes are detected in the manpage outputs. This can be used for CI to be notified when the manpages are out of date. Additionally, the date used in new manpages will match those in the existing manpages (to allow comparison without factoring in the date).
* `--link`:
  This is now done automatically by `brew update`.

### `mirror` *`formulae`*

Reuploads the stable URL for a formula to Bintray to use it as a mirror.


### `prof` [*`ruby options`*]

Run Homebrew with the Ruby profiler.

*Example:* `brew prof readall`


### `pull` [*`options`*] *`patch sources`*

Get a patch from a GitHub commit or pull request and apply it to Homebrew.
Optionally, publish updated bottles for the formulae changed by the patch.

Each *`patch source`* may be one of:

  ~ The ID number of a PR (pull request) in the homebrew/core GitHub
    repository

  ~ The URL of a PR on GitHub, using either the web page or API URL
    formats. In this form, the PR may be on Homebrew/brew,
    Homebrew/homebrew-core or any tap.

  ~ The URL of a commit on GitHub

  ~ A "https://jenkins.brew.sh/job/..." string specifying a testing job ID

* `--bottle`:
  Handle bottles, pulling the bottle-update commit and publishing files on Bintray.
* `--bump`:
  For one-formula PRs, automatically reword commit message to our preferred format.
* `--clean`:
  Do not rewrite or otherwise modify the commits found in the pulled PR.
* `--ignore-whitespace`:
  Silently ignore whitespace discrepancies when applying diffs.
* `--resolve`:
  When a patch fails to apply, leave in progress and allow user to resolve, instead of aborting.
* `--branch-okay`:
  Do not warn if pulling to a branch besides master (useful for testing).
* `--no-pbcopy`:
  Do not copy anything to the system clipboard.
* `--no-publish`:
  Do not publish bottles to Bintray.
* `--warn-on-publish-failure`:
  Do not exit if there's a failure publishing bottles on Bintray.
* `--bintray-org`:
  Publish bottles at the provided Bintray *`organisation`*.
* `--test-bot-user`:
  Pull the bottle block commit from the provided *`user`* on GitHub.
* `--tap`:
  Apply the PR to the specified tap.

### `release-notes` [*`options`*] [*`previous_tag`*] [*`end_ref`*]

Print the merged pull requests on Homebrew/brew between two Git refs.
If no *`previous_tag`* is provided it defaults to the latest tag.
If no *`end_ref`* is provided it defaults to `origin/master`.

* `--markdown`:
  Print as a Markdown list.

### `ruby` [*`ruby options`*]

Run a Ruby instance with Homebrew's libraries loaded.

*Example:* `brew ruby -e "puts :gcc.f.deps"` or `brew ruby script.rb`

* `-e`:
  Execute the provided string argument as a script.

### `tap-new` *`user`*`/`*`repo`*

Generate the template files for a new tap.


### `test` [*`options`*] *`formulae`*

Run the test method provided by an installed formula.
There is no standard output or return code, but generally it should notify the
user if something is wrong with the installed formula.

*Example:* `brew install jruby && brew test jruby`

* `--devel`:
  Test the development version of a formula.
* `--HEAD`:
  Test the head version of a formula.
* `--keep-tmp`:
  Keep the temporary files created for the test.

### `tests` [*`options`*]

Run Homebrew's unit and integration tests.

* `--coverage`:
  Generate code coverage reports.
* `--generic`:
  Run only OS-agnostic tests.
* `--no-compat`:
  Do not load the compatibility layer when running tests.
* `--online`:
  Include tests that use the GitHub API and tests that use any of the taps for official external commands.
* `--only`:
  Run only *`test_script`*`_spec.rb`. Appending `:`*`line_number`* will start at a specific line.
* `--seed`:
  Randomize tests with the provided *`value`* instead of a random seed.

### `update-test` [*`options`*]

Run a test of `brew update` with a new repository clone.
If no arguments are passed, use `origin/master` as the start commit.

* `--to-tag`:
  Set `HOMEBREW_UPDATE_TO_TAG` to test updating between tags.
* `--keep-tmp`:
  Retain the temporary directory containing the new repository clone.
* `--commit`:
  Use provided *`commit`* as the start commit.
* `--before`:
  Use the commit at provided *`date`* as the start commit.

  * `vendor-gems`:
    Install and commit Homebrew's vendored gems.

## GLOBAL OPTIONS

These options are applicable across all sub-commands.

* `-q`, `--quiet`:
  Suppress any warnings.

* `-v`, `--verbose`:
  Make some output more verbose.

* `-d`, `--debug`:
  Display any debugging information.

* `-f`, `--force`:
  Override warnings and enable potentially unsafe operations.

## OFFICIAL EXTERNAL COMMANDS

  * `bundle` *`subcommand`*

  Bundler for non-Ruby dependencies from Homebrew, Homebrew Cask and the Mac App Store.

       --file=                        read the `Brewfile` from this file. Use `--file=-` to output to stdin/stdout.
       --global                       read the `Brewfile` from `~/.Brewfile`.

  `brew bundle` [`install`] [`-v`|`--verbose`] [`--no-upgrade`] [`--file=`*`path`*|`--global`]

  Install or upgrade all dependencies in a Brewfile.

       -v, --verbose                  print the output from commands as they are run.
       --no-upgrade                   don't run `brew upgrade` on outdated dependencies. Note they may still be upgraded by `brew install` if needed.

  `brew bundle dump` [`--force`] [`--describe`] [`--file=`*`path`*|`--global`]

  Write all installed casks/formulae/taps into a Brewfile.

       --force                        overwrite an existing `Brewfile`.
       --describe                     output a description comment above each line. This comment will not be output if the dependency does not have a description.

  `brew bundle cleanup` [`--force`] [`--zap`] [`--file=`*`path`*|`--global`]

  Uninstall all dependencies not listed in a Brewfile.

       --force                        actually perform the cleanup operations.
       --zap                          casks will be removed using the `zap` command instead of `uninstall`.

  `brew bundle check` [`--no-upgrade`] [`--file=`*`path`*|`--global`] [`--verbose`]

  Check if all dependencies are installed in a Brewfile.

       --no-upgrade                   ignore outdated dependencies.
       -v, --verbose                  output and check for all missing dependencies.

  `brew bundle exec` *`command`*

  Run an external command in an isolated build environment.

  `brew bundle list` [`--all`|`--brews`|`--casks`|`--taps`|`--mas`] [`--file=`*`path`*|`--global`]

  List all dependencies present in a Brewfile. By default, only brew dependencies are output.

       --all                          output all dependencies.
       --brews                        output Homebrew dependencies.
       --casks                        output Homebrew Cask dependencies.
       --taps                         output tap dependencies.
       --mas                          output Mac App Store dependencies.

    **Homebrew/homebrew-bundle**: <https://github.com/Homebrew/homebrew-bundle>

  * `cask` [`--version` | `audit` | `cat` | `cleanup` | `create` | `doctor` | `edit` | `fetch` | `home` | `info`]:
    Install macOS applications distributed as binaries.

    **Homebrew/homebrew-cask**: <https://github.com/Homebrew/homebrew-cask>

  * `services` *`subcommand`*:

  Manage background services with macOS' `launchctl`(1) daemon manager

       --all                           run *`subcommand`* on all services.

  [`sudo`] `brew services list`

  List all running services for the current user (or root).

  [`sudo`] `brew services run` (*`formula`*|`--all`)

  Run the service *`formula`* without registering to launch at login (or boot).

  [`sudo`] `brew services start` (*`formula`*|`--all`)

  Start the service *`formula`* immediately and register it to launch at login (or boot).

  [`sudo`] `brew services stop` (*`formula`*|`--all`)

  Stop the service *`formula`* immediately and unregister it from launching at login (or boot).

  [`sudo`] `brew services restart` (*`formula`*|`--all`)

  Stop (if necessary) and start the service *`formula`* immediately and register it to launch at login (or boot).

  [`sudo`] `brew services cleanup`

  Remove all unused services.

  If `sudo` is passed, operate on `/Library/LaunchDaemons` (started at boot).
  Otherwise, operate on `~/Library/LaunchAgents` (started at login).

    **Homebrew/homebrew-services**: <https://github.com/Homebrew/homebrew-services>

## CUSTOM EXTERNAL COMMANDS

Homebrew, like `git`(1), supports external commands. These are executable
scripts that reside somewhere in the `PATH`, named `brew-`*`cmdname`* or
`brew-`*`cmdname`*`.rb`, which can be invoked like `brew` *`cmdname`*. This allows you
to create your own commands without modifying Homebrew's internals.

Instructions for creating your own commands can be found in the docs:
<https://docs.brew.sh/External-Commands>

## SPECIFYING FORMULAE

Many Homebrew commands accept one or more *`formula`* arguments. These arguments
can take several different forms:

  * The name of a formula:
    e.g. `git`, `node`, `wget`.

  * The fully-qualified name of a tapped formula:
    Sometimes a formula from a tapped repository may conflict with one in
    `homebrew/core`.
    You can still access these formulae by using a special syntax, e.g.
    `homebrew/dupes/vim` or `homebrew/versions/node4`.

  * An arbitrary file or URL:
    Homebrew can install formulae via URL, e.g.
    `https://raw.githubusercontent.com/Homebrew/homebrew-core/master/Formula/git.rb`,
    or from a local path. It could point to either a formula file or a bottle.
    In the case of a URL, the downloaded file will be cached for later use.

## ENVIRONMENT

Note that environment variables must have a value set to be detected. For example,
`export HOMEBREW_NO_INSECURE_REDIRECT=1` rather than just
`export HOMEBREW_NO_INSECURE_REDIRECT`.

  * `HOMEBREW_ARTIFACT_DOMAIN`:
    If set, instructs Homebrew to prefix all download URLs, including those for bottles,
    with this variable. For example, `HOMEBREW_ARTIFACT_DOMAIN=http://localhost:8080`
    will cause a formula with the URL `https://example.com/foo.tar.gz` to instead
    download from `http://localhost:8080/example.com/foo.tar.gz`.

  * `HOMEBREW_AUTO_UPDATE_SECS`:
    If set, Homebrew will only check for autoupdates once per this seconds interval.

    *Default:* `60`.

  * `HOMEBREW_AWS_ACCESS_KEY_ID`, `HOMEBREW_AWS_SECRET_ACCESS_KEY`:
    When using the `S3` download strategy, Homebrew will look in
    these variables for access credentials (see
    <https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html#cli-environment>
    to retrieve these access credentials from AWS). If they are not set,
    the `S3` download strategy will download with a public (unsigned) URL.

  * `HOMEBREW_BOTTLE_DOMAIN`:
    By default, Homebrew uses `https://homebrew.bintray.com/` as its download
    mirror for bottles. If set, instructs Homebrew to instead use the specified
    URL. For example, `HOMEBREW_BOTTLE_DOMAIN=http://localhost:8080` will
    cause all bottles to download from the prefix `http://localhost:8080/`.

  * `HOMEBREW_BROWSER`:
    If set, Homebrew uses this setting as the browser when opening project
    homepages, instead of the OS default browser.

  * `HOMEBREW_CACHE`:
    If set, instructs Homebrew to use the specified directory as the download cache.

    *Default:* `~/Library/Caches/Homebrew`.

  * `HOMEBREW_CURLRC`:
    If set, Homebrew will not pass `-q` when invoking `curl`(1) (which disables
    the use of `curlrc`).

  * `HOMEBREW_CURL_VERBOSE`:
    If set, Homebrew will pass `--verbose` when invoking `curl`(1).

  * `HOMEBREW_DEBUG`:
    If set, any commands that can emit debugging information will do so.

  * `HOMEBREW_DEVELOPER`:
    If set, Homebrew will tweak behaviour to be more relevant for Homebrew
    developers (active or budding), e.g. turning warnings into errors.

  * `HOMEBREW_EDITOR`:
    If set, Homebrew will use this editor when editing a single formula, or
    several formulae in the same directory.

    *Note:* `brew edit` will open all of Homebrew as discontinuous files and
    directories. TextMate can handle this correctly in project mode, but many
    editors will do strange things in this case.

  * `HOMEBREW_FORCE_BREWED_CURL`:
    If set, Homebrew will always use a Homebrew-installed `curl` rather than the
    system version. Automatically set if the system version of `curl` is too old.

  * `HOMEBREW_FORCE_VENDOR_RUBY`:
    If set, Homebrew will always use its vendored, relocatable Ruby version
    even if the system version of Ruby is new enough.

  * `HOMEBREW_FORCE_BREWED_GIT`:
    If set, Homebrew will always use a Homebrew-installed `git` rather than the
    system version. Automatically set if the system version of `git` is too old.

  * `HOMEBREW_GITHUB_API_TOKEN`:
    A personal access token for the GitHub API, used by Homebrew for features
    such as `brew search`. You can create one at <https://github.com/settings/tokens>.
    If set, GitHub will allow you a greater number of API requests. For more
    information, see: <https://developer.github.com/v3/#rate-limiting>

    *Note:* Homebrew doesn't require permissions for any of the scopes.

  * `HOMEBREW_INSTALL_BADGE`:
    Text printed before the installation summary of each successful build.

    *Default:* the beer emoji.

  * `HOMEBREW_INSTALL_CLEANUP`:
    If set, `brew install`, `brew upgrade` and `brew reinstall` will remove
    previously installed version(s) of the installed/upgraded formulae.

    If `brew cleanup` has not been run in 30 days then it will be run at this
    time.

    This will become the default in a later version of Homebrew. To opt-out see
    `HOMEBREW_NO_INSTALL_CLEANUP`.

  * `HOMEBREW_LOGS`:
    If set, Homebrew will use the specified directory to store log files.

  * `HOMEBREW_MAKE_JOBS`:
    If set, instructs Homebrew to use the value of `HOMEBREW_MAKE_JOBS` as
    the number of parallel jobs to run when building with `make`(1).

    *Default:* the number of available CPU cores.

  * `HOMEBREW_NO_ANALYTICS`:
    If set, Homebrew will not send analytics. See: <https://docs.brew.sh/Analytics>

  * `HOMEBREW_NO_AUTO_UPDATE`:
    If set, Homebrew will not auto-update before running `brew install`,
    `brew upgrade` or `brew tap`.

  * `HOMEBREW_NO_BOTTLE_SOURCE_FALLBACK`:
    If set, Homebrew will fail on the failure of installation from a bottle
    rather than falling back to building from source.

  * `HOMEBREW_NO_COLOR`:
    If set, Homebrew will not print text with color added.

  * `HOMEBREW_NO_EMOJI`:
    If set, Homebrew will not print the `HOMEBREW_INSTALL_BADGE` on a
    successful build.

    *Note:* Homebrew will only try to print emoji on OS X Lion or newer.

  * `HOMEBREW_NO_INSECURE_REDIRECT`:
    If set, Homebrew will not permit redirects from secure HTTPS
    to insecure HTTP.

    While ensuring your downloads are fully secure, this is likely
    to cause from-source SourceForge, some GNU & GNOME based
    formulae to fail to download.

  * `HOMEBREW_NO_GITHUB_API`:
    If set, Homebrew will not use the GitHub API, e.g. for searches or
    fetching relevant issues on a failed install.

  * `HOMEBREW_NO_INSTALL_CLEANUP`:
    If set, `brew install`, `brew upgrade` and `brew reinstall` will never
    automatically remove the previously installed version(s) of the
    installed/upgraded formulae.

  * `HOMEBREW_PRY`:
    If set, Homebrew will use Pry for the `brew irb` command.

  * `HOMEBREW_SVN`:
    When exporting from Subversion, Homebrew will use `HOMEBREW_SVN` if set,
    a Homebrew-built Subversion if installed, or the system-provided binary.

    Set this to force Homebrew to use a particular `svn` binary.

  * `HOMEBREW_TEMP`:
    If set, instructs Homebrew to use `HOMEBREW_TEMP` as the temporary directory
    for building packages. This may be needed if your system temp directory and
    Homebrew prefix are on different volumes, as macOS has trouble moving
    symlinks across volumes when the target does not yet exist.

    This issue typically occurs when using FileVault or custom SSD configurations.

  * `HOMEBREW_UPDATE_TO_TAG`:
    If set, instructs Homebrew to always use the latest stable tag (even if
    developer commands have been run).

  * `HOMEBREW_VERBOSE`:
    If set, Homebrew always assumes `--verbose` when running commands.

  * `http_proxy`:
    Sets the HTTP proxy to be used by `curl`, `git` and `svn` when downloading
    through Homebrew.

  * `https_proxy`:
    Sets the HTTPS proxy to be used by `curl`, `git` and `svn` when downloading
    through Homebrew.

  * `all_proxy`:
    Sets the SOCKS5 proxy to be used by `curl`, `git` and `svn` when downloading
    through Homebrew.

  * `ftp_proxy`:
    Sets the FTP proxy to be used by `curl`, `git` and `svn` when downloading
    through Homebrew.

  * `no_proxy`:
    Sets the comma-separated list of hostnames and domain names that should be excluded
    from proxying by `curl`, `git` and `svn` when downloading through Homebrew.

## USING HOMEBREW BEHIND A PROXY

Set the `http_proxy`, `https_proxy`, `all_proxy`, `ftp_proxy` and/or `no_proxy`
environment variables documented above.

For example, to use an unauthenticated HTTP or SOCKS5 proxy:

    export http_proxy=http://$HOST:$PORT

    export all_proxy=socks5://$HOST:$PORT

And for an authenticated HTTP proxy:

    export http_proxy=http://$USER:$PASSWORD@$HOST:$PORT

## SEE ALSO

Homebrew Documentation: <https://docs.brew.sh>

`brew-cask`(1), `git`(1), `git-log`(1)

## LINUXBREW AUTHORS

Linuxbrew's lead maintainer is Shaun Jackman.

Linuxbrew/homebrew-core's lead maintainer is Michka Popoff.

Linuxbrew's other current maintainers are Piotr Gaczkowski, Maxim Belkin, Jonathan Chang, and Alyssa Ross.

Former Linuxbrew maintainers with significant contributions include Bob W. Hogg.

## HOMEBREW AUTHORS

Homebrew's lead maintainer is Mike McQuaid.

Homebrew's project leadership committee is Mike McQuaid, Misty De Meo and Markus Reiter.

Homebrew/brew's other current maintainers are Claudia Pellegrino, Michka Popoff, Shaun Jackman, Chongyu Zhu, Vitor Galvao, Misty De Meo, Gautham Goli, Markus Reiter, Steven Peters, Jonathan Chang and William Woodruff.

Homebrew/brew's Linux support (and Linuxbrew) maintainers are Michka Popoff and Shaun Jackman.

Homebrew/homebrew-core's other current maintainers are Claudia Pellegrino, Igor Kapkov, Michka Popoff, Shaun Jackman, Chongyu Zhu, Izaak Beekman, Sean Molenaar, Jan Viljanen, Jason Tedor, Viktor Szakats, FX Coudert, Thierry Moisan, Steven Peters, Misty De Meo and Tom Schoonjans.

Former maintainers with significant contributions include JCount, commitay, Dominyk Tiller, Tim Smith, Baptiste Fontaine, Xu Cheng, Martin Afanasjew, Brett Koonce, Charlie Sharpsteen, Jack Nagel, Adam Vandenberg, Andrew Janke, Alex Dunn, neutric, Tomasz Pajor, Uladzislau Shablinski, Alyssa Ross, ilovezfs and Homebrew's creator: Max Howell.

## BUGS

See our issues on GitHub:

  * **Homebrew/brew**:
    <https://github.com/Homebrew/brew/issues>

  * **Homebrew/homebrew-core**:
    <https://github.com/Homebrew/homebrew-core/issues>


[SYNOPSIS]: #SYNOPSIS "SYNOPSIS"
[DESCRIPTION]: #DESCRIPTION "DESCRIPTION"
[ESSENTIAL COMMANDS]: #ESSENTIAL-COMMANDS "ESSENTIAL COMMANDS"
[COMMANDS]: #COMMANDS "COMMANDS"
[DEVELOPER COMMANDS]: #DEVELOPER-COMMANDS "DEVELOPER COMMANDS"
[GLOBAL OPTIONS]: #GLOBAL-OPTIONS "GLOBAL OPTIONS"
[OFFICIAL EXTERNAL COMMANDS]: #OFFICIAL-EXTERNAL-COMMANDS "OFFICIAL EXTERNAL COMMANDS"
[CUSTOM EXTERNAL COMMANDS]: #CUSTOM-EXTERNAL-COMMANDS "CUSTOM EXTERNAL COMMANDS"
[SPECIFYING FORMULAE]: #SPECIFYING-FORMULAE "SPECIFYING FORMULAE"
[ENVIRONMENT]: #ENVIRONMENT "ENVIRONMENT"
[USING HOMEBREW BEHIND A PROXY]: #USING-HOMEBREW-BEHIND-A-PROXY "USING HOMEBREW BEHIND A PROXY"
[SEE ALSO]: #SEE-ALSO "SEE ALSO"
[LINUXBREW AUTHORS]: #LINUXBREW-AUTHORS "LINUXBREW AUTHORS"
[HOMEBREW AUTHORS]: #HOMEBREW-AUTHORS "HOMEBREW AUTHORS"
[BUGS]: #BUGS "BUGS"


[-]: -.html
