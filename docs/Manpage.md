brew(1) -- The missing package manager for macOS
===============================================

## SYNOPSIS

`brew` `--version`<br>
`brew` `command` [`--verbose`|`-v`] [`options`] [`formula`] ...

## DESCRIPTION

Homebrew is the easiest and most flexible way to install the UNIX tools Apple
didn't include with macOS.

## ESSENTIAL COMMANDS

For the full command list, see the [COMMANDS](#commands) section.

With `--verbose` or `-v`, many commands print extra debugging information. Note that these flags should only appear after a command.

  * `install` `formula`:
    Install `formula`.

  * `uninstall` `formula`:
    Uninstall `formula`.

  * `update`:
    Fetch the newest version of Homebrew from GitHub using `git`(1).

  * `list`:
    List all installed formulae.

  * `search` (`text`|`/``text``/`):
    Perform a substring search of formula names for `text`. If `text` is
    surrounded with slashes, then it is interpreted as a regular expression.
    The search for `text` is extended online to some popular taps.
    If no search term is given, all locally available formulae are listed.

## COMMANDS

  * `analytics` [`state`]:
    Display anonymous user behaviour analytics state.
    Read more at <https://docs.brew.sh/Analytics.html>.

  * `analytics` (`on`|`off`):
    Turn on/off Homebrew's analytics.

  * `analytics` `regenerate-uuid`:
    Regenerate UUID used in Homebrew's analytics.

  * `cat` `formula`:
    Display the source to `formula`.

  * `cleanup` [`--prune=``days`] [`--dry-run`] [`-s`] [`formulae`]:
    For all installed or specific formulae, remove any older versions from the
    cellar. In addition, old downloads from the Homebrew download-cache are deleted.

    If `--prune=``days` is specified, remove all cache files older than `days`.

    If `--dry-run` or `-n` is passed, show what would be removed, but do not
    actually remove anything.

    If `-s` is passed, scrub the cache, removing downloads for even the latest
    versions of formulae. Note downloads for any installed formulae will still not be
    deleted. If you want to delete those too: `rm -rf $(brew --cache)`

  * `command` `cmd`:
    Display the path to the file which is used when invoking `brew` `cmd`.

  * `commands` [`--quiet` [`--include-aliases`]]:
    Show a list of built-in and external commands.

    If `--quiet` is passed, list only the names of commands without the header.
    With `--include-aliases`, the aliases of internal commands will be included.

  * `config`:
    Show Homebrew and system configuration useful for debugging. If you file
    a bug report, you will likely be asked for this information if you do not
    provide it.

  * `deps` [`--1`] [`-n`] [`--union`] [`--full-name`] [`--installed`] [`--include-build`] [`--include-optional`] [`--skip-recommended`] [`--include-requirements`] `formulae`:
    Show dependencies for `formulae`. When given multiple formula arguments,
    show the intersection of dependencies for `formulae`.

    If `--1` is passed, only show dependencies one level down, instead of
    recursing.

    If `-n` is passed, show dependencies in topological order.

    If `--union` is passed, show the union of dependencies for `formulae`,
    instead of the intersection.

    If `--full-name` is passed, list dependencies by their full name.

    If `--installed` is passed, only list those dependencies that are
    currently installed.

    By default, `deps` shows required and recommended dependencies for
    `formulae`. To include the `:build` type dependencies, pass `--include-build`.
    Similarly, pass `--include-optional` to include `:optional` dependencies.
    To skip `:recommended` type dependencies, pass `--skip-recommended`.
    To include requirements in addition to dependencies, pass `--include-requirements`.

  * `deps` `--tree` [`--1`] [`filters`] [`--annotate`] (`formulae`|`--installed`):
    Show dependencies as a tree. When given multiple formula arguments, output
    individual trees for every formula.

    If `--1` is passed, only one level of children is displayed.

    If `--installed` is passed, output a tree for every installed formula.

    The `filters` placeholder is any combination of options `--include-build`,
    `--include-optional`, `--skip-recommended`, and `--include-requirements` as
    documented above.

    If `--annotate` is passed, the build, optional, and recommended dependencies
    are marked as such in the output.

  * `deps` [`filters`] (`--installed`|`--all`):
    Show dependencies for installed or all available formulae. Every line of
    output starts with the formula name, followed by a colon and all direct
    dependencies of that formula.

    The `filters` placeholder is any combination of options `--include-build`,
    `--include-optional`, and `--skip-recommended` as documented above.

  * `desc` `formula`:
    Display `formula`'s name and one-line description.

  * `desc` [`-s`|`-n`|`-d`] (`text`|`/``text``/`):
    Search both name and description (`-s`), just the names (`-n`), or just  the
    descriptions (`-d`) for `text`. If `text` is flanked by slashes, it is interpreted
    as a regular expression. Formula descriptions are cached; the cache is created on
    the first search, making that search slower than subsequent ones.

  * `diy` [`--name=``name`] [`--version=``version`]:
    Automatically determine the installation prefix for non-Homebrew software.

    Using the output from this command, you can install your own software into
    the Cellar and then link it into Homebrew's prefix with `brew link`.

    The options `--name=``name` and `--version=``version` each take an argument
    and allow you to explicitly set the name and version of the package you are
    installing.

  * `doctor`:
    Check your system for potential problems. Doctor exits with a non-zero status
    if any problems are found.

  * `fetch` [`--force`] [`--retry`] [`-v`] [`--devel`|`--HEAD`] [`--deps`] [`--build-from-source`|`--force-bottle`] `formulae`:
    Download the source packages for the given `formulae`.
    For tarballs, also print SHA-256 checksums.

    If `--HEAD` or `--devel` is passed, fetch that version instead of the
    stable version.

    If `-v` is passed, do a verbose VCS checkout, if the URL represents a VCS.
    This is useful for seeing if an existing VCS cache has been updated.

    If `--force` (or `-f`) is passed, remove a previously cached version and re-fetch.

    If `--retry` is passed, retry if a download fails or re-download if the
    checksum of a previously cached version no longer matches.

    If `--deps` is passed, also download dependencies for any listed `formulae`.

    If `--build-from-source` (or `-s`) is passed, download the source rather than a
    bottle.

    If `--force-bottle` is passed, download a bottle if it exists for the
    current or newest version of macOS, even if it would not be used during
    installation.

  * `gist-logs` [`--new-issue`|`-n`] `formula`:
    Upload logs for a failed build of `formula` to a new Gist.

    `formula` is usually the name of the formula to install, but it can be specified
    in several different ways. See [SPECIFYING FORMULAE](#specifying-formulae).

    If `--new-issue` is passed, automatically create a new issue in the appropriate
    GitHub repository as well as creating the Gist.

    If no logs are found, an error message is presented.

  * `home`:
    Open Homebrew's own homepage in a browser.

  * `home` `formula`:
    Open `formula`'s homepage in a browser.

  * `info` `formula`:
    Display information about `formula`.

  * `info` `--github` `formula`:
    Open a browser to the GitHub History page for formula `formula`.

    To view formula history locally: `brew log -p `formula``

  * `info` `--json=``version` (`--all`|`--installed`|`formulae`):
    Print a JSON representation of `formulae`. Currently the only accepted value
    for `version` is `v1`.

    Pass `--all` to get information on all formulae, or `--installed` to get
    information on all installed formulae.

    See the docs for examples of using the JSON output:
    <https://docs.brew.sh/Querying-Brew.html>

  * `install` [`--debug`] [`--env=`(`std`|`super`)] [`--ignore-dependencies`|`--only-dependencies`] [`--cc=``compiler`] [`--build-from-source`|`--force-bottle`] [`--devel`|`--HEAD`] [`--keep-tmp`] [`--build-bottle`] `formula` [`options` ...]:
    Install `formula`.

    `formula` is usually the name of the formula to install, but it can be specified
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

    If `--cc=``compiler` is passed, attempt to compile using `compiler`.
    `compiler` should be the name of the compiler's executable, for instance
    `gcc-4.2` for Apple's GCC 4.2, or `gcc-4.9` for a Homebrew-provided GCC
    4.9.

    If `--build-from-source` (or `-s`) is passed, compile the specified `formula` from
    source even if a bottle is provided. Dependencies will still be installed
    from bottles if they are available.

    If `HOMEBREW_BUILD_FROM_SOURCE` is set, regardless of whether `--build-from-source` was
    passed, then both `formula` and the dependencies installed as part of this process
    are built from source even if bottles are available.

    If `--force-bottle` is passed, install from a bottle if it exists for the
    current or newest version of macOS, even if it would not normally be used
    for installation.

    If `--devel` is passed, and `formula` defines it, install the development version.

    If `--HEAD` is passed, and `formula` defines it, install the HEAD version,
    aka master, trunk, unstable.

    If `--keep-tmp` is passed, the temporary files created during installation
    are not deleted.

    If `--build-bottle` is passed, prepare the formula for eventual bottling
    during installation.

    Installation options specific to `formula` may be appended to the command,
    and can be listed with `brew options` `formula`.

  * `install` `--interactive` [`--git`] `formula`:
    If `--interactive` (or `-i`) is passed, download and patch `formula`, then
    open a shell. This allows the user to run `./configure --help` and
    otherwise determine how to turn the software package into a Homebrew
    formula.

    If `--git` (or `-g`) is passed, Homebrew will create a Git repository, useful for
    creating patches to the software.

  * `irb` [`--examples`]:
    Enter the interactive Homebrew Ruby shell.

    If `--examples` is passed, several examples will be shown.

  * `leaves`:
    Show installed formulae that are not dependencies of another installed formula.

  * `ln`, `link` [`--overwrite`] [`--dry-run`] [`--force`] `formula`:
    Symlink all of `formula`'s installed files into the Homebrew prefix. This
    is done automatically when you install formulae but can be useful for DIY
    installations.

    If `--overwrite` is passed, Homebrew will delete files which already exist in
    the prefix while linking.

    If `--dry-run` or `-n` is passed, Homebrew will list all files which would
    be linked or which would be deleted by `brew link --overwrite`, but will not
    actually link or delete any files.

    If `--force` (or `-f`) is passed, Homebrew will allow keg-only formulae to be linked.

  * `linkapps` [`--local`] [`formulae`]:
    Find installed formulae that provide `.app`-style macOS apps and symlink them
    into `/Applications`, allowing for easier access (deprecated).

    Unfortunately `brew linkapps` cannot behave nicely with e.g. Spotlight using
    either aliases or symlinks and Homebrew formulae do not build "proper" `.app`
    bundles that can be relocated. Instead, please consider using `brew cask` and
    migrate formulae using `.app`s to casks.

    If no `formulae` are provided, all of them will have their apps symlinked.

    If provided, `--local` will symlink them into the user's `~/Applications`
    directory instead of the system directory.

  * `list`, `ls` [`--full-name`]:
    List all installed formulae. If `--full-name` is passed, print formulae
    with fully-qualified names. If `--full-name` is not passed, any other
    options (e.g. `-t`) are passed to `ls` which produces the actual output.

  * `list`, `ls` `--unbrewed`:
    List all files in the Homebrew prefix not installed by Homebrew.

  * `list`, `ls` [`--versions` [`--multiple`]] [`--pinned`] [`formulae`]:
    List the installed files for `formulae`. Combined with `--verbose`, recursively
    list the contents of all subdirectories in each `formula`'s keg.

    If `--versions` is passed, show the version number for installed formulae,
    or only the specified formulae if `formulae` are given. With `--multiple`,
    only show formulae with multiple versions installed.

    If `--pinned` is passed, show the versions of pinned formulae, or only the
    specified (pinned) formulae if `formulae` are given.
    See also `pin`, `unpin`.

  * `log` [`git-log-options`] `formula` ...:
    Show the git log for the given formulae. Options that `git-log`(1)
    recognizes can be passed before the formula list.

  * `migrate` [`--force`] `formulae`:
    Migrate renamed packages to new name, where `formulae` are old names of
    packages.

    If `--force` (or `-f`) is passed, then treat installed `formulae` and passed `formulae`
    like if they are from same taps and migrate them anyway.

  * `missing` [`--hide=``hidden`] [`formulae`]:
    Check the given `formulae` for missing dependencies. If no `formulae` are
    given, check all installed brews.

    If `--hide=``hidden` is passed, act as if none of `hidden` are installed.
    `hidden` should be a comma-separated list of formulae.

  * `options` [`--compact`] (`--all`|`--installed`|`formulae`):
    Display install options specific to `formulae`.

    If `--compact` is passed, show all options on a single line separated by
    spaces.

    If `--all` is passed, show options for all formulae.

    If `--installed` is passed, show options for all installed formulae.

  * `outdated` [`--quiet`|`--verbose`|`--json=``version`] [`--fetch-HEAD`]:
    Show formulae that have an updated version available.

    By default, version information is displayed in interactive shells, and
    suppressed otherwise.

    If `--quiet` is passed, list only the names of outdated brews (takes
    precedence over `--verbose`).

    If `--verbose` (or `-v`) is passed, display detailed version information.

    If `--json=``version` is passed, the output will be in JSON format. The only
    valid version is `v1`.

    If `--fetch-HEAD` is passed, fetch the upstream repository to detect if
    the HEAD installation of the formula is outdated. Otherwise, the
    repository's HEAD will be checked for updates when a new stable or devel
    version has been released.

  * `pin` `formulae`:
    Pin the specified `formulae`, preventing them from being upgraded when
    issuing the `brew upgrade `formulae`` command (but can still be upgraded
    as dependencies for other formulae). See also `unpin`.

  * `postinstall` `formula`:
    Rerun the post-install steps for `formula`.

  * `prune` [`--dry-run`]:
    Remove dead symlinks from the Homebrew prefix. This is generally not
    needed, but can be useful when doing DIY installations. Also remove broken
    app symlinks from `/Applications` and `~/Applications` that were previously
    created by `brew linkapps`.

    If `--dry-run` or `-n` is passed, show what would be removed, but do not
    actually remove anything.

  * `reinstall` `formula`:
    Uninstall and then install `formula`.

  * `search`, `-S`:
    Display all locally available formulae for brewing (including tapped ones).
    No online search is performed if called without arguments.

  * `search` [`--desc`] (`text`|`/``text``/`):
    Perform a substring search of formula names for `text`. If `text` is
    surrounded with slashes, then it is interpreted as a regular expression.
    The search for `text` is extended online to some popular taps.

    If `--desc` is passed, browse available packages matching `text` including a
    description for each.

  * `search` (`--debian`|`--fedora`|`--fink`|`--macports`|`--opensuse`|`--ubuntu`) `text`:
    Search for `text` in the given package manager's list.

  * `sh` [`--env=std`]:
    Start a Homebrew build environment shell. Uses our years-battle-hardened
    Homebrew build logic to help your `./configure && make && make install`
    or even your `gem install` succeed. Especially handy if you run Homebrew
    in an Xcode-only configuration since it adds tools like `make` to your `PATH`
    which otherwise build systems would not find.

    If `--env=std` is passed, use the standard `PATH` instead of superenv's.

  * `style` [`--fix`] [`--display-cop-names`] [`--only-cops=`[COP1,COP2..]|`--except-cops=`[COP1,COP2..]] [`files`|`taps`|`formulae`]:
    Check formulae or files for conformance to Homebrew style guidelines.

    `formulae` and `files` may not be combined. If both are omitted, style will run
    style checks on the whole Homebrew `Library`, including core code and all
    formulae.

    If `--fix` is passed, style violations will be automatically fixed using
    RuboCop's `--auto-correct` feature.

    If `--display-cop-names` is passed, the RuboCop cop name for each violation
    is included in the output.

    If `--only-cops` is passed, only the given Rubocop cop(s)' violations would be checked.

    If `--except-cops` is passed, the given Rubocop cop(s)' checks would be skipped.

    Exits with a non-zero status if any style violations are found.

  * `switch` `name` `version`:
    Symlink all of the specific `version` of `name`'s install to Homebrew prefix.

  * `tap`:
    List all installed taps.

  * `tap` [`--full`] `user``/``repo` [`URL`]:
    Tap a formula repository.

    With `URL` unspecified, taps a formula repository from GitHub using HTTPS.
    Since so many taps are hosted on GitHub, this command is a shortcut for
    `tap `user`/`repo` https://github.com/`user`/homebrew-`repo``.

    With `URL` specified, taps a formula repository from anywhere, using
    any transport protocol that `git` handles. The one-argument form of `tap`
    simplifies but also limits. This two-argument command makes no
    assumptions, so taps can be cloned from places other than GitHub and
    using protocols other than HTTPS, e.g., SSH, GIT, HTTP, FTP(S), RSYNC.

    By default, the repository is cloned as a shallow copy (`--depth=1`), but
    if `--full` is passed, a full clone will be used. To convert a shallow copy
    to a full copy, you can retap passing `--full` without first untapping.

    `tap` is re-runnable and exits successfully if there's nothing to do.
    However, retapping with a different `URL` will cause an exception, so first
    `untap` if you need to modify the `URL`.

  * `tap` `--repair`:
    Migrate tapped formulae from symlink-based to directory-based structure.

  * `tap` `--list-official`:
    List all official taps.

  * `tap` `--list-pinned`:
    List all pinned taps.

  * `tap-info`:
    Display a brief summary of all installed taps.

  * `tap-info` (`--installed`|`taps`):
    Display detailed information about one or more `taps`.

    Pass `--installed` to display information on all installed taps.

  * `tap-info` `--json=``version` (`--installed`|`taps`):
    Print a JSON representation of `taps`. Currently the only accepted value
    for `version` is `v1`.

    Pass `--installed` to get information on installed taps.

    See the docs for examples of using the JSON output:
    <https://docs.brew.sh/Querying-Brew.html>

  * `tap-pin` `tap`:
    Pin `tap`, prioritizing its formulae over core when formula names are supplied
    by the user. See also `tap-unpin`.

  * `tap-unpin` `tap`:
    Unpin `tap` so its formulae are no longer prioritized. See also `tap-pin`.

  * `uninstall`, `rm`, `remove` [`--force`] [`--ignore-dependencies`] `formula`:
    Uninstall `formula`.

    If `--force` (or `-f`) is passed, and there are multiple versions of `formula`
    installed, delete all installed versions.

    If `--ignore-dependencies` is passed, uninstalling won't fail, even if
    formulae depending on `formula` would still be installed.

  * `unlink` [`--dry-run`] `formula`:
    Remove symlinks for `formula` from the Homebrew prefix. This can be useful
    for temporarily disabling a formula:
    `brew unlink `formula` && `commands` && brew link `formula``

    If `--dry-run` or `-n` is passed, Homebrew will list all files which would
    be unlinked, but will not actually unlink or delete any files.

  * `unlinkapps` [`--local`] [`--dry-run`] [`formulae`]:
    Remove symlinks created by `brew linkapps` from `/Applications` (deprecated).

    Unfortunately `brew linkapps` cannot behave nicely with e.g. Spotlight using
    either aliases or symlinks and Homebrew formulae do not build "proper" `.app`
    bundles that can be relocated. Instead, please consider using `brew cask` and
    migrate formulae using `.app`s to casks.

    If no `formulae` are provided, all linked apps will be removed.

    If provided, `--local` will remove symlinks from the user's `~/Applications`
    directory instead of the system directory.

    If `--dry-run` or `-n` is passed, Homebrew will list all symlinks which
    would be removed, but will not actually delete any files.

  * `unpack` [`--git`|`--patch`] [`--destdir=``path`] `formulae`:
    Unpack the source files for `formulae` into subdirectories of the current
    working directory. If `--destdir=``path` is given, the subdirectories will
    be created in the directory named by `path` instead.

    If `--patch` is passed, patches for `formulae` will be applied to the
    unpacked source.

    If `--git` (or `-g`) is passed, a Git repository will be initialized in the unpacked
    source. This is useful for creating patches for the software.

  * `unpin` `formulae`:
    Unpin `formulae`, allowing them to be upgraded by `brew upgrade `formulae``.
    See also `pin`.

  * `untap` `tap`:
    Remove a tapped repository.

  * `update` [`--merge`] [`--force`]:
    Fetch the newest version of Homebrew and all formulae from GitHub using
    `git`(1) and perform any necessary migrations.

    If `--merge` is specified then `git merge` is used to include updates
    (rather than `git rebase`).

    If `--force` (or `-f`) is specified then always do a slower, full update check even
    if unnecessary.

  * `upgrade` [`install-options`] [`--cleanup`] [`--fetch-HEAD`] [`formulae`]:
    Upgrade outdated, unpinned brews.

    Options for the `install` command are also valid here.

    If `--cleanup` is specified then remove previously installed `formula` version(s).

    If `--fetch-HEAD` is passed, fetch the upstream repository to detect if
    the HEAD installation of the formula is outdated. Otherwise, the
    repository's HEAD will be checked for updates when a new stable or devel
    version has been released.

    If `formulae` are given, upgrade only the specified brews (but do so even
    if they are pinned; see `pin`, `unpin`).

  * `uses` [`--installed`] [`--recursive`] [`--include-build`] [`--include-optional`] [`--skip-recommended`] [`--devel`|`--HEAD`] `formulae`:
    Show the formulae that specify `formulae` as a dependency. When given
    multiple formula arguments, show the intersection of formulae that use
    `formulae`.

    Use `--recursive` to resolve more than one level of dependencies.

    If `--installed` is passed, only list installed formulae.

    By default, `uses` shows all formulae that specify `formulae` as a required
    or recommended dependency. To include the `:build` type dependencies, pass
    `--include-build`. Similarly, pass `--include-optional` to include `:optional`
    dependencies. To skip `:recommended` type dependencies, pass `--skip-recommended`.

    By default, `uses` shows usages of `formulae` by stable builds. To find
    cases where `formulae` is used by development or HEAD build, pass
    `--devel` or `--HEAD`.

  * `--cache`:
    Display Homebrew's download cache. See also `HOMEBREW_CACHE`.

  * `--cache` `formula`:
    Display the file or directory used to cache `formula`.

  * `--cellar`:
    Display Homebrew's Cellar path. *Default:* `$(brew --prefix)/Cellar`, or if
    that directory doesn't exist, `$(brew --repository)/Cellar`.

  * `--cellar` `formula`:
    Display the location in the cellar where `formula` would be installed,
    without any sort of versioned directory as the last path.

  * `--env`:
    Show a summary of the Homebrew build environment.

  * `--prefix`:
    Display Homebrew's install path. *Default:* `/usr/local`

  * `--prefix` `formula`:
    Display the location in the cellar where `formula` is or would be installed.

  * `--repository`:
    Display where Homebrew's `.git` directory is located.

  * `--repository` `user``/``repo`:
    Display where tap `user``/``repo`'s directory is located.

  * `--version`:
    Print the version number of Homebrew to standard output and exit.

## DEVELOPER COMMANDS

  * `audit` [`--strict`] [`--fix`] [`--online`] [`--new-formula`] [`--display-cop-names`] [`--display-filename`] [`--only=``method`|`--except=``method`] [`--only-cops=`[COP1,COP2..]|`--except-cops=`[COP1,COP2..]] [`formulae`]:
    Check `formulae` for Homebrew coding style violations. This should be
    run before submitting a new formula.

    If no `formulae` are provided, all of them are checked.

    If `--strict` is passed, additional checks are run, including RuboCop
    style checks.

    If `--fix` is passed, style violations will be
    automatically fixed using RuboCop's `--auto-correct` feature.

    If `--online` is passed, additional slower checks that require a network
    connection are run.

    If `--new-formula` is passed, various additional checks are run that check
    if a new formula is eligible for Homebrew. This should be used when creating
    new formulae and implies `--strict` and `--online`.

    If `--display-cop-names` is passed, the RuboCop cop name for each violation
    is included in the output.

    If `--display-filename` is passed, every line of output is prefixed with the
    name of the file or formula being audited, to make the output easy to grep.

    If `--only` is passed, only the methods named `audit_`method`` will be run.

    If `--except` is passed, the methods named `audit_`method`` will not be run.

    If `--only-cops` is passed, only the given Rubocop cop(s)' violations would be checked.

    If `--except-cops` is passed, the given Rubocop cop(s)' checks would be skipped.

    `audit` exits with a non-zero status if any errors are found. This is useful,
    for instance, for implementing pre-commit hooks.

  * `bottle` [`--verbose`] [`--no-rebuild`|`--keep-old`] [`--skip-relocation`] [`--root-url=``URL`] [`--force-core-tap`] `formulae`:
    Generate a bottle (binary package) from a formula installed with
    `--build-bottle`.

    If the formula specifies a rebuild version, it will be incremented in the
    generated DSL. Passing `--keep-old` will attempt to keep it at its
    original value, while `--no-rebuild` will remove it.

    If `--verbose` (or `-v`) is passed, print the bottling commands and any warnings
    encountered.

    If `--skip-relocation` is passed, do not check if the bottle can be marked
    as relocatable.

    If `--root-url` is passed, use the specified `URL` as the root of the
    bottle's URL instead of Homebrew's default.

    If `--force-core-tap` is passed, build a bottle even if `formula` is not
    in homebrew/core or any installed taps.

  * `bottle` `--merge` [`--keep-old`] [`--write` [`--no-commit`]] `formulae`:
    Generate a bottle from a formula and print the new DSL merged into the
    existing formula.

    If `--write` is passed, write the changes to the formula file. A new
    commit will then be generated unless `--no-commit` is passed.

  * `bump-formula-pr` [`--devel`] [`--dry-run` [`--write`]] [`--audit`|`--strict`] [`--mirror=``URL`] [`--version=``version`] [`--message=``message`] (`--url=``URL` `--sha256=``sha-256`|`--tag=``tag` `--revision=``revision`) `formula`:
    Creates a pull request to update the formula with a new URL or a new tag.

    If a `URL` is specified, the `sha-256` checksum of the new download must
    also be specified. A best effort to determine the `sha-256` and `formula`
    name will be made if either or both values are not supplied by the user.

    If a `tag` is specified, the git commit `revision` corresponding to that
    tag must also be specified.

    If `--devel` is passed, bump the development rather than stable version.
    The development spec must already exist.

    If `--dry-run` is passed, print what would be done rather than doing it.

    If `--write` is passed along with `--dry-run`, perform a not-so-dry run
    making the expected file modifications but not taking any git actions.

    If `--audit` is passed, run `brew audit` before opening the PR.

    If `--strict` is passed, run `brew audit --strict` before opening the PR.

    If `--mirror=``URL` is passed, use the value as a mirror URL.

    If `--version=``version` is passed, use the value to override the value
    parsed from the URL or tag. Note that `--version=0` can be used to delete
    an existing `version` override from a formula if it has become redundant.

    If `--message=``message` is passed, append `message` to the default PR
    message.

    Note that this command cannot be used to transition a formula from a
    URL-and-sha256 style specification into a tag-and-revision style
    specification, nor vice versa. It must use whichever style specification
    the preexisting formula already uses.

  * `create` `URL` [`--autotools`|`--cmake`|`--meson`] [`--no-fetch`] [`--set-name` `name`] [`--set-version` `version`] [`--tap` `user``/``repo`]:
    Generate a formula for the downloadable file at `URL` and open it in the editor.
    Homebrew will attempt to automatically derive the formula name
    and version, but if it fails, you'll have to make your own template. The `wget`
    formula serves as a simple example. For the complete API have a look at
    <http://www.rubydoc.info/github/Homebrew/brew/master/Formula>.

    If `--autotools` is passed, create a basic template for an Autotools-style build.
    If `--cmake` is passed, create a basic template for a CMake-style build.
    If `--meson` is passed, create a basic template for a Meson-style build.

    If `--no-fetch` is passed, Homebrew will not download `URL` to the cache and
    will thus not add the SHA256 to the formula for you. It will also not check
    the GitHub API for GitHub projects (to fill out the description and homepage).

    The options `--set-name` and `--set-version` each take an argument and allow
    you to explicitly set the name and version of the package you are creating.

    The option `--tap` takes a tap as its argument and generates the formula in
    the specified tap.

  * `edit`:
    Open all of Homebrew for editing.

  * `edit` `formula`:
    Open `formula` in the editor.

  * `formula` `formula`:
    Display the path where `formula` is located.

  * `linkage` [`--test`] [`--reverse`]  `formula`:
    Checks the library links of an installed formula.

    Only works on installed formulae. An error is raised if it is run on
    uninstalled formulae.

    If `--test` is passed, only display missing libraries and exit with a
    non-zero exit code if any missing libraries were found.

    If `--reverse` is passed, print the dylib followed by the binaries
    which link to it for each library the keg references.

  * `man` [`--fail-if-changed`]:
    Generate Homebrew's manpages.

    If `--fail-if-changed` is passed, the command will return a failing
    status code if changes are detected in the manpage outputs.
    This can be used for CI to be notified when the manpages are out of date.
    Additionally, the date used in new manpages will match those in the existing
    manpages (to allow comparison without factoring in the date).

  * `pull` [`--bottle`] [`--bump`] [`--clean`] [`--ignore-whitespace`] [`--resolve`] [`--branch-okay`] [`--no-pbcopy`] [`--no-publish`] [`--warn-on-publish-failure`] `patch-source` [`patch-source`]:

    Gets a patch from a GitHub commit or pull request and applies it to Homebrew.
    Optionally, installs the formulae changed by the patch.

    Each `patch-source` may be one of:

      ~ The ID number of a PR (pull request) in the homebrew/core GitHub
        repository

      ~ The URL of a PR on GitHub, using either the web page or API URL
        formats. In this form, the PR may be on Homebrew/brew,
        Homebrew/homebrew-core or any tap.

      ~ The URL of a commit on GitHub

      ~ A "https://jenkins.brew.sh/job/..." string specifying a testing job ID

    If `--bottle` is passed, handle bottles, pulling the bottle-update
    commit and publishing files on Bintray.

    If `--bump` is passed, for one-formula PRs, automatically reword
    commit message to our preferred format.

    If `--clean` is passed, do not rewrite or otherwise modify the
    commits found in the pulled PR.

    If `--ignore-whitespace` is passed, silently ignore whitespace
    discrepancies when applying diffs.

    If `--resolve` is passed, when a patch fails to apply, leave in
    progress and allow user to resolve, instead of aborting.

    If `--branch-okay` is passed, do not warn if pulling to a branch
    besides master (useful for testing).

    If `--no-pbcopy` is passed, do not copy anything to the system
    clipboard.

    If `--no-publish` is passed, do not publish bottles to Bintray.

    If `--warn-on-publish-failure` was passed, do not exit if there's a
    failure publishing bottles on Bintray.

  * `release-notes` [`--markdown`] [`previous_tag`] [`end_ref`]:
    Output the merged pull requests on Homebrew/brew between two Git refs.
    If no `previous_tag` is provided it defaults to the newest tag.
    If no `end_ref` is provided it defaults to `origin/master`.

    If `--markdown` is passed, output as a Markdown list.

  * `tap-new` `user``/``repo`:
    Generate the template files for a new tap.

  * `test` [`--devel`|`--HEAD`] [`--debug`] [`--keep-tmp`] `formula`:
    Most formulae provide a test method. `brew test` `formula` runs this
    test method. There is no standard output or return code, but it should
    generally indicate to the user if something is wrong with the installed
    formula.

    To test the development or head version of a formula, use `--devel` or
    `--HEAD`.

    If `--debug` (or `-d`) is passed and the test fails, an interactive debugger will be
    launched with access to IRB or a shell inside the temporary test directory.

    If `--keep-tmp` is passed, the temporary files created for the test are
    not deleted.

    Example: `brew install jruby && brew test jruby`

  * `tests` [`--verbose`] [`--coverage`] [`--generic`] [`--no-compat`] [`--only=``test_script`[`:``line_number`]] [`--seed` `seed`] [`--online`] [`--official-cmd-taps`]:
    Run Homebrew's unit and integration tests. If provided,
    `--only=``test_script` runs only `test_script`_spec.rb, and `--seed`
    randomizes tests with the provided value instead of a random seed.

    If `--verbose` (or `-v`) is passed, print the command that runs the tests.

    If `--coverage` is passed, also generate code coverage reports.

    If `--generic` is passed, only run OS-agnostic tests.

    If `--no-compat` is passed, do not load the compatibility layer when
    running tests.

    If `--online` is passed, include tests that use the GitHub API and tests
    that use any of the taps for official external commands.

  * `update-test` [`--commit=``commit`] [`--before=``date`] [`--to-tag`] [`--keep-tmp`]:
    Runs a test of `brew update` with a new repository clone.

    If no arguments are passed, use `origin/master` as the start commit.

    If `--commit=``commit` is passed, use `commit` as the start commit.

    If `--before=``date` is passed, use the commit at `date` as the
    start commit.

    If `--to-tag` is passed, set `HOMEBREW_UPDATE_TO_TAG` to test updating
    between tags.

    If `--keep-tmp` is passed, retain the temporary directory containing
    the new repository clone.

## OFFICIAL EXTERNAL COMMANDS

  * `bundle`:
    Bundler for non-Ruby dependencies from Homebrew:
    <https://github.com/Homebrew/homebrew-bundle>

  * `cask`:
    Install macOS applications distributed as binaries:
    <https://github.com/caskroom/homebrew-cask>

  * `services`:
    Integrates Homebrew formulae with macOS's `launchctl`(1) manager:
    <https://github.com/Homebrew/homebrew-services>

## CUSTOM EXTERNAL COMMANDS

Homebrew, like `git`(1), supports external commands. These are executable
scripts that reside somewhere in the `PATH`, named `brew-``cmdname` or
`brew-``cmdname``.rb`, which can be invoked like `brew` `cmdname`. This allows you
to create your own commands without modifying Homebrew's internals.

Instructions for creating your own commands can be found in the docs:
<https://docs.brew.sh/External-Commands.html>

## SPECIFYING FORMULAE

Many Homebrew commands accept one or more `formula` arguments. These arguments
can take several different forms:

  * The name of a formula:
    e.g. `git`, `node`, `wget`.

  * The fully-qualified name of a tapped formula:
    Sometimes a formula from a tapped repository may conflict with one in
    `homebrew/core`.
    You can still access these formulae by using a special syntax, e.g.
    `homebrew/dupes/vim` or `homebrew/versions/node4`.

  * An arbitrary URL:
    Homebrew can install formulae via URL, e.g.
    `https://raw.github.com/Homebrew/homebrew-core/master/Formula/git.rb`.
    The formula file will be cached for later use.

## ENVIRONMENT
  * `HOMEBREW_ARTIFACT_DOMAIN`:
    If set, instructs Homebrew to use the given URL as a download mirror for bottles and binaries.

  * `HOMEBREW_AUTO_UPDATE_SECS`:
    If set, Homebrew will only check for autoupdates once per this seconds interval.

    *Default:* `60`.

  * `HOMEBREW_AWS_ACCESS_KEY_ID`, `HOMEBREW_AWS_SECRET_ACCESS_KEY`:
    When using the `S3` download strategy, Homebrew will look in
    these variables for access credentials (see
    <https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html#cli-environment>
    to retrieve these access credentials from AWS).  If they are not set,
    the `S3` download strategy will download with a public
    (unsigned) URL.

  * `HOMEBREW_BOTTLE_DOMAIN`:
    If set, instructs Homebrew to use the given URL as a download mirror for bottles.

  * `HOMEBREW_BROWSER`:
    If set, uses this setting as the browser when opening project homepages,
    instead of the OS default browser.

  * `HOMEBREW_BUILD_FROM_SOURCE`:
    If set, instructs Homebrew to compile from source even when a formula
    provides a bottle. This environment variable is intended for use by
    Homebrew developers. Please do not file issues if you encounter errors when
    using this environment variable.

  * `HOMEBREW_CACHE`:
    If set, instructs Homebrew to use the given directory as the download cache.

    *Default:* `~/Library/Caches/Homebrew`.

  * `HOMEBREW_CURL_VERBOSE`:
    If set, Homebrew will pass `--verbose` when invoking `curl`(1).

  * `HOMEBREW_DEBUG`:
    If set, any commands that can emit debugging information will do so.

  * `HOMEBREW_DEBUG_INSTALL`:
    When `brew install -d` or `brew install -i` drops into a shell,
    `HOMEBREW_DEBUG_INSTALL` will be set to the name of the formula being
    brewed.

  * `HOMEBREW_DEBUG_PREFIX`:
    When `brew install -d` or `brew install -i` drops into a shell,
    `HOMEBREW_DEBUG_PREFIX` will be set to the target prefix in the Cellar
    of the formula being brewed.

  * `HOMEBREW_DEVELOPER`:
    If set, Homebrew will tweak behaviour to be more relevant for Homebrew
    developers (active or budding) e.g. turning warnings into errors.

  * `HOMEBREW_EDITOR`:
    If set, Homebrew will use this editor when editing a single formula, or
    several formulae in the same directory.

    *Note:* `brew edit` will open all of Homebrew as discontinuous files and
    directories. TextMate can handle this correctly in project mode, but many
    editors will do strange things in this case.

  * `HOMEBREW_FORCE_VENDOR_RUBY`:
    If set, Homebrew will always use its vendored, relocatable Ruby 2.0 version
    even if the system version of Ruby is >=2.0.

  * `HOMEBREW_GIT`:
    When using Git, Homebrew will use `GIT` if set,
    a Homebrew-built Git if installed, or the system-provided binary.

    Set this to force Homebrew to use a particular git binary.

  * `HOMEBREW_GITHUB_API_TOKEN`:
    A personal access token for the GitHub API, which you can create at
    <https://github.com/settings/tokens>. If set, GitHub will allow you a
    greater number of API requests. See
    <https://developer.github.com/v3/#rate-limiting> for more information.
    Homebrew uses the GitHub API for features such as `brew search`.

    *Note:* Homebrew doesn't require permissions for any of the scopes.

  * `HOMEBREW_LOGS`:
    If set, Homebrew will use the given directory to store log files.

  * `HOMEBREW_MAKE_JOBS`:
    If set, instructs Homebrew to use the value of `HOMEBREW_MAKE_JOBS` as
    the number of parallel jobs to run when building with `make`(1).

    *Default:* the number of available CPU cores.

  * `HOMEBREW_NO_ANALYTICS`:
    If set, Homebrew will not send analytics. See: <https://docs.brew.sh/Analytics.html>

  * `HOMEBREW_NO_AUTO_UPDATE`:
    If set, Homebrew will not auto-update before running `brew install`,
    `brew upgrade` or `brew tap`.

  * `HOMEBREW_NO_EMOJI`:
    If set, Homebrew will not print the `HOMEBREW_INSTALL_BADGE` on a
    successful build.

    *Note:* Homebrew will only try to print emoji on Lion or newer.

  * `HOMEBREW_NO_INSECURE_REDIRECT`:
    If set, Homebrew will not permit redirects from secure HTTPS
    to insecure HTTP.

    While ensuring your downloads are fully secure, this is likely
    to cause from-source SourceForge, some GNU & GNOME based
    formulae to fail to download.

  * `HOMEBREW_NO_GITHUB_API`:
    If set, Homebrew will not use the GitHub API for e.g searches or
    fetching relevant issues on a failed install.

  * `HOMEBREW_INSTALL_BADGE`:
    Text printed before the installation summary of each successful build.
    Defaults to the beer emoji.

  * `HOMEBREW_SVN`:
    When exporting from Subversion, Homebrew will use `HOMEBREW_SVN` if set,
    a Homebrew-built Subversion if installed, or the system-provided binary.

    Set this to force Homebrew to use a particular `svn` binary.

  * `HOMEBREW_TEMP`:
    If set, instructs Homebrew to use `HOMEBREW_TEMP` as the temporary directory
    for building packages. This may be needed if your system temp directory and
    Homebrew Prefix are on different volumes, as macOS has trouble moving
    symlinks across volumes when the target does not yet exist.

    This issue typically occurs when using FileVault or custom SSD
    configurations.

  * `HOMEBREW_VERBOSE`:
    If set, Homebrew always assumes `--verbose` when running commands.

## USING HOMEBREW BEHIND A PROXY

Homebrew uses several commands for downloading files (e.g. `curl`, `git`, `svn`).
Many of these tools can download via a proxy. It's common for these tools
to read proxy parameters from environment variables.

For the majority of cases setting `http_proxy` is enough. You can set this in
your shell profile, or you can use it before a brew command:

    http_proxy=http://`host`:`port` brew install foo

If your proxy requires authentication:

    http_proxy=http://`user`:`password`@`host`:`port` brew install foo

## SEE ALSO

Homebrew Documentation: <https://docs.brew.sh>

`brew-cask`(1), `git`(1), `git-log`(1)

## AUTHORS

Homebrew's lead maintainer is Mike McQuaid.

Homebrew/homebrew-core's lead maintainer is ilovezfs.

Homebrew's other current maintainers are Alyssa Ross, Andrew Janke, Alex Dunn, FX Coudert, Josh Hagins, JCount, Misty De Meo, neutric, Tomasz Pajor, Markus Reiter, Tim Smith, Tom Schoonjans, Uladzislau Shablinski and William Woodruff.

Former maintainers with significant contributions include Baptiste Fontaine, Xu Cheng, Martin Afanasjew, Dominyk Tiller, Brett Koonce, Charlie Sharpsteen, Jack Nagel, Adam Vandenberg and Homebrew's creator: Max Howell.

## BUGS

See our issues on GitHub:

 * Homebrew/brew <https://github.com/Homebrew/brew/issues>

 * Homebrew/homebrew-core <https://github.com/Homebrew/homebrew-core/issues>


[SYNOPSIS]: #SYNOPSIS "SYNOPSIS"
[DESCRIPTION]: #DESCRIPTION "DESCRIPTION"
[ESSENTIAL COMMANDS]: #ESSENTIAL-COMMANDS "ESSENTIAL COMMANDS"
[COMMANDS]: #COMMANDS "COMMANDS"
[DEVELOPER COMMANDS]: #DEVELOPER-COMMANDS "DEVELOPER COMMANDS"
[OFFICIAL EXTERNAL COMMANDS]: #OFFICIAL-EXTERNAL-COMMANDS "OFFICIAL EXTERNAL COMMANDS"
[CUSTOM EXTERNAL COMMANDS]: #CUSTOM-EXTERNAL-COMMANDS "CUSTOM EXTERNAL COMMANDS"
[SPECIFYING FORMULAE]: #SPECIFYING-FORMULAE "SPECIFYING FORMULAE"
[ENVIRONMENT]: #ENVIRONMENT "ENVIRONMENT"
[USING HOMEBREW BEHIND A PROXY]: #USING-HOMEBREW-BEHIND-A-PROXY "USING HOMEBREW BEHIND A PROXY"
[SEE ALSO]: #SEE-ALSO "SEE ALSO"
[AUTHORS]: #AUTHORS "AUTHORS"
[BUGS]: #BUGS "BUGS"


[-]: -.html
