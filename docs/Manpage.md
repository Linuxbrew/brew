brew(1) -- The missing package manager for macOS
===============================================

## SYNOPSIS

`brew` `--version`<br>
`brew` <var>command</var> [`--verbose`|`-v`] [<var>options</var>] [<var>formula</var>] ...

## DESCRIPTION

Homebrew is the easiest and most flexible way to install the UNIX tools Apple
didn't include with macOS.

## ESSENTIAL COMMANDS

For the full command list, see the [COMMANDS][] section.

With `--verbose` or `-v`, many commands print extra debugging information. Note that these flags should only appear after a command.

  * `install` <var>formula</var>:
    Install <var>formula</var>.

  * `uninstall` <var>formula</var>:
    Uninstall <var>formula</var>.

  * `update`:
    Fetch the newest version of Homebrew from GitHub using `git`(1).

  * `list`:
    List all installed formulae.

  * `search` (<var>text</var>|`/`<var>text</var>`/`):
    Perform a substring search of formula names for <var>text</var>. If <var>text</var> is
    surrounded with slashes, then it is interpreted as a regular expression.
    The search for <var>text</var> is extended online to some popular taps.
    If no search term is given, all locally available formulae are listed.

## COMMANDS

  * `analytics` [`state`]:
    Display anonymous user behaviour analytics state.
    Read more at <http://docs.brew.sh/Analytics.html>.

  * `analytics` (`on`|`off`):
    Turn on/off Homebrew's analytics.

  * `analytics` `regenerate-uuid`:
    Regenerate UUID used in Homebrew's analytics.

  * `cat` <var>formula</var>:
    Display the source to <var>formula</var>.

  * `cleanup` [`--prune=`<var>days</var>] [`--dry-run`] [`-s`] [<var>formulae</var>]:
    For all installed or specific formulae, remove any older versions from the
    cellar. In addition, old downloads from the Homebrew download-cache are deleted.

    If `--prune=`<var>days</var> is specified, remove all cache files older than <var>days</var>.

    If `--dry-run` or `-n` is passed, show what would be removed, but do not
    actually remove anything.

    If `-s` is passed, scrub the cache, removing downloads for even the latest
    versions of formulae. Note downloads for any installed formulae will still not be
    deleted. If you want to delete those too: `rm -rf $(brew --cache)`

  * `command` <var>cmd</var>:
    Display the path to the file which is used when invoking `brew` <var>cmd</var>.

  * `commands` [`--quiet` [`--include-aliases`]]:
    Show a list of built-in and external commands.

    If `--quiet` is passed, list only the names of commands without the header.
    With `--include-aliases`, the aliases of internal commands will be included.

  * `config`:
    Show Homebrew and system configuration useful for debugging. If you file
    a bug report, you will likely be asked for this information if you do not
    provide it.

  * `deps` [`--1`] [`-n`] [`--union`] [`--full-name`] [`--installed`] [`--include-build`] [`--include-optional`] [`--skip-recommended`] <var>formulae</var>:
    Show dependencies for <var>formulae</var>. When given multiple formula arguments,
    show the intersection of dependencies for <var>formulae</var>.

    If `--1` is passed, only show dependencies one level down, instead of
    recursing.

    If `-n` is passed, show dependencies in topological order.

    If `--union` is passed, show the union of dependencies for <var>formulae</var>,
    instead of the intersection.

    If `--full-name` is passed, list dependencies by their full name.

    If `--installed` is passed, only list those dependencies that are
    currently installed.

    By default, `deps` shows required and recommended dependencies for
    <var>formulae</var>. To include the `:build` type dependencies, pass `--include-build`.
    Similarly, pass `--include-optional` to include `:optional` dependencies.
    To skip `:recommended` type dependencies, pass `--skip-recommended`.

  * `deps` `--tree` [<var>filters</var>] (<var>formulae</var>|`--installed`):
    Show dependencies as a tree. When given multiple formula arguments, output
    individual trees for every formula.

    If `--installed` is passed, output a tree for every installed formula.

    The <var>filters</var> placeholder is any combination of options `--include-build`,
    `--include-optional`, and `--skip-recommended` as documented above.

  * `deps` [<var>filters</var>] (`--installed`|`--all`):
    Show dependencies for installed or all available formulae. Every line of
    output starts with the formula name, followed by a colon and all direct
    dependencies of that formula.

    The <var>filters</var> placeholder is any combination of options `--include-build`,
    `--include-optional`, and `--skip-recommended` as documented above.

  * `desc` <var>formula</var>:
    Display <var>formula</var>'s name and one-line description.

  * `desc` [`-s`|`-n`|`-d`] (<var>text</var>|`/`<var>text</var>`/`):
    Search both name and description (`-s`), just the names (`-n`), or just  the
    descriptions (`-d`) for <var>text</var>. If <var>text</var> is flanked by slashes, it is interpreted
    as a regular expression. Formula descriptions are cached; the cache is created on
    the first search, making that search slower than subsequent ones.

  * `diy` [`--name=`<var>name</var>] [`--version=`<var>version</var>]:
    Automatically determine the installation prefix for non-Homebrew software.

    Using the output from this command, you can install your own software into
    the Cellar and then link it into Homebrew's prefix with `brew link`.

    The options `--name=`<var>name</var> and `--version=`<var>version</var> each take an argument
    and allow you to explicitly set the name and version of the package you are
    installing.

  * `doctor`:
    Check your system for potential problems. Doctor exits with a non-zero status
    if any problems are found.

  * `fetch` [`--force`] [`--retry`] [`-v`] [`--devel`|`--HEAD`] [`--deps`] [`--build-from-source`|`--force-bottle`] <var>formulae</var>:
    Download the source packages for the given <var>formulae</var>.
    For tarballs, also print SHA-256 checksums.

    If `--HEAD` or `--devel` is passed, fetch that version instead of the
    stable version.

    If `-v` is passed, do a verbose VCS checkout, if the URL represents a VCS.
    This is useful for seeing if an existing VCS cache has been updated.

    If `--force` is passed, remove a previously cached version and re-fetch.

    If `--retry` is passed, retry if a download fails or re-download if the
    checksum of a previously cached version no longer matches.

    If `--deps` is passed, also download dependencies for any listed <var>formulae</var>.

    If `--build-from-source` is passed, download the source rather than a
    bottle.

    If `--force-bottle` is passed, download a bottle if it exists for the
    current or newest version of macOS, even if it would not be used during
    installation.

  * `gist-logs` [`--new-issue`|`-n`] <var>formula</var>:
    Upload logs for a failed build of <var>formula</var> to a new Gist.

    <var>formula</var> is usually the name of the formula to install, but it can be specified
    in several different ways. See [SPECIFYING FORMULAE][].

    If `--new-issue` is passed, automatically create a new issue in the appropriate
    GitHub repository as well as creating the Gist.

    If no logs are found, an error message is presented.

  * `home`:
    Open Homebrew's own homepage in a browser.

  * `home` <var>formula</var>:
    Open <var>formula</var>'s homepage in a browser.

  * `info` <var>formula</var>:
    Display information about <var>formula</var>.

  * `info` `--github` <var>formula</var>:
    Open a browser to the GitHub History page for formula <var>formula</var>.

    To view formula history locally: `brew log -p <var>formula</var>`

  * `info` `--json=`<var>version</var> (`--all`|`--installed`|<var>formulae</var>):
    Print a JSON representation of <var>formulae</var>. Currently the only accepted value
    for <var>version</var> is `v1`.

    Pass `--all` to get information on all formulae, or `--installed` to get
    information on all installed formulae.

    See the docs for examples of using the JSON output:
    <http://docs.brew.sh/Querying-Brew.html>

  * `install` [`--debug`] [`--env=`(`std`|`super`)] [`--ignore-dependencies`|`--only-dependencies`] [`--cc=`<var>compiler</var>] [`--build-from-source`|`--force-bottle`] [`--devel`|`--HEAD`] [`--keep-tmp`] [`--build-bottle`] <var>formula</var>:
    Install <var>formula</var>.

    <var>formula</var> is usually the name of the formula to install, but it can be specified
    in several different ways. See [SPECIFYING FORMULAE][].

    If `--debug` is passed and brewing fails, open an interactive debugging
    session with access to IRB or a shell inside the temporary build directory.

    If `--env=std` is passed, use the standard build environment instead of superenv.

    If `--env=super` is passed, use superenv even if the formula specifies the
    standard build environment.

    If `--ignore-dependencies` is passed, skip installing any dependencies of
    any kind. If they are not already present, the formula will probably fail
    to install.

    If `--only-dependencies` is passed, install the dependencies with specified
    options but do not install the specified formula.

    If `--cc=`<var>compiler</var> is passed, attempt to compile using <var>compiler</var>.
    <var>compiler</var> should be the name of the compiler's executable, for instance
    `gcc-4.2` for Apple's GCC 4.2, or `gcc-4.9` for a Homebrew-provided GCC
    4.9.

    If `--build-from-source` or `-s` is passed, compile the specified <var>formula</var> from
    source even if a bottle is provided. Dependencies will still be installed
    from bottles if they are available.

    If `HOMEBREW_BUILD_FROM_SOURCE` is set, regardless of whether `--build-from-source` was
    passed, then both <var>formula</var> and the dependencies installed as part of this process
    are built from source even if bottles are available.

    If `--force-bottle` is passed, install from a bottle if it exists for the
    current or newest version of macOS, even if it would not normally be used
    for installation.

    If `--devel` is passed, and <var>formula</var> defines it, install the development version.

    If `--HEAD` is passed, and <var>formula</var> defines it, install the HEAD version,
    aka master, trunk, unstable.

    If `--keep-tmp` is passed, the temporary files created during installation
    are not deleted.

    If `--build-bottle` is passed, prepare the formula for eventual bottling
    during installation.

  * `install` `--interactive` [`--git`] <var>formula</var>:
    Download and patch <var>formula</var>, then open a shell. This allows the user to
    run `./configure --help` and otherwise determine how to turn the software
    package into a Homebrew formula.

    If `--git` is passed, Homebrew will create a Git repository, useful for
    creating patches to the software.

  * `irb` [`--examples`]:
    Enter the interactive Homebrew Ruby shell.

    If `--examples` is passed, several examples will be shown.

  * `leaves`:
    Show installed formulae that are not dependencies of another installed formula.

  * `ln`, `link` [`--overwrite`] [`--dry-run`] [`--force`] <var>formula</var>:
    Symlink all of <var>formula</var>'s installed files into the Homebrew prefix. This
    is done automatically when you install formulae but can be useful for DIY
    installations.

    If `--overwrite` is passed, Homebrew will delete files which already exist in
    the prefix while linking.

    If `--dry-run` or `-n` is passed, Homebrew will list all files which would
    be linked or which would be deleted by `brew link --overwrite`, but will not
    actually link or delete any files.

    If `--force` is passed, Homebrew will allow keg-only formulae to be linked.

  * `linkapps` [`--local`] [<var>formulae</var>]:
    Find installed formulae that provide `.app`-style macOS apps and symlink them
    into `/Applications`, allowing for easier access (deprecated).

    Unfortunately `brew linkapps` cannot behave nicely with e.g. Spotlight using
    either aliases or symlinks and Homebrew formulae do not build "proper" `.app`
    bundles that can be relocated. Instead, please consider using `brew cask` and
    migrate formulae using `.app`s to casks.

    If no <var>formulae</var> are provided, all of them will have their apps symlinked.

    If provided, `--local` will symlink them into the user's `~/Applications`
    directory instead of the system directory.

  * `list`, `ls` [`--full-name`]:
    List all installed formulae. If `--full-name` is passed, print formulae
    with fully-qualified names. If `--full-name` is not passed, any other
    options (e.g. `-t`) are passed to `ls` which produces the actual output.

  * `list`, `ls` `--unbrewed`:
    List all files in the Homebrew prefix not installed by Homebrew.

  * `list`, `ls` [`--versions` [`--multiple`]] [`--pinned`] [<var>formulae</var>]:
    List the installed files for <var>formulae</var>. Combined with `--verbose`, recursively
    list the contents of all subdirectories in each <var>formula</var>'s keg.

    If `--versions` is passed, show the version number for installed formulae,
    or only the specified formulae if <var>formulae</var> are given. With `--multiple`,
    only show formulae with multiple versions installed.

    If `--pinned` is passed, show the versions of pinned formulae, or only the
    specified (pinned) formulae if <var>formulae</var> are given.
    See also `pin`, `unpin`.

  * `log` [<var>git-log-options</var>] <var>formula</var> ...:
    Show the git log for the given formulae. Options that `git-log`(1)
    recognizes can be passed before the formula list.

  * `migrate` [`--force`] <var>formulae</var>:
    Migrate renamed packages to new name, where <var>formulae</var> are old names of
    packages.

    If `--force` is passed, then treat installed <var>formulae</var> and passed <var>formulae</var>
    like if they are from same taps and migrate them anyway.

  * `missing` [`--hide=`<var>hidden</var>] [<var>formulae</var>]:
    Check the given <var>formulae</var> for missing dependencies. If no <var>formulae</var> are
    given, check all installed brews.

    If `--hide=`<var>hidden</var> is passed, act as if none of <var>hidden</var> are installed.
    <var>hidden</var> should be a comma-separated list of formulae.

  * `options` [`--compact`] (`--all`|`--installed`|<var>formulae</var>):
    Display install options specific to <var>formulae</var>.

    If `--compact` is passed, show all options on a single line separated by
    spaces.

    If `--all` is passed, show options for all formulae.

    If `--installed` is passed, show options for all installed formulae.

  * `outdated` [`--quiet`|`--verbose`|`--json=`<var>version</var>] [`--fetch-HEAD`]:
    Show formulae that have an updated version available.

    By default, version information is displayed in interactive shells, and
    suppressed otherwise.

    If `--quiet` is passed, list only the names of outdated brews (takes
    precedence over `--verbose`).

    If `--verbose` is passed, display detailed version information.

    If `--json=`<var>version</var> is passed, the output will be in JSON format. The only
    valid version is `v1`.

    If `--fetch-HEAD` is passed, fetch the upstream repository to detect if
    the HEAD installation of the formula is outdated. Otherwise, the
    repository's HEAD will be checked for updates when a new stable or devel
    version has been released.

  * `pin` <var>formulae</var>:
    Pin the specified <var>formulae</var>, preventing them from being upgraded when
    issuing the `brew upgrade` command. See also `unpin`.

  * `postinstall` <var>formula</var>:
    Rerun the post-install steps for <var>formula</var>.

  * `prune` [`--dry-run`]:
    Remove dead symlinks from the Homebrew prefix. This is generally not
    needed, but can be useful when doing DIY installations. Also remove broken
    app symlinks from `/Applications` and `~/Applications` that were previously
    created by `brew linkapps`.

    If `--dry-run` or `-n` is passed, show what would be removed, but do not
    actually remove anything.

  * `reinstall` <var>formula</var>:
    Uninstall and then install <var>formula</var>.

  * `search`, `-S`:
    Display all locally available formulae for brewing (including tapped ones).
    No online search is performed if called without arguments.

  * `search` [`--desc`] (<var>text</var>|`/`<var>text</var>`/`):
    Perform a substring search of formula names for <var>text</var>. If <var>text</var> is
    surrounded with slashes, then it is interpreted as a regular expression.
    The search for <var>text</var> is extended online to some popular taps.

    If `--desc` is passed, browse available packages matching <var>text</var> including a
    description for each.

  * `search` (`--debian`|`--fedora`|`--fink`|`--macports`|`--opensuse`|`--ubuntu`) <var>text</var>:
    Search for <var>text</var> in the given package manager's list.

  * `sh` [`--env=std`]:
    Start a Homebrew build environment shell. Uses our years-battle-hardened
    Homebrew build logic to help your `./configure && make && make install`
    or even your `gem install` succeed. Especially handy if you run Homebrew
    in an Xcode-only configuration since it adds tools like `make` to your `PATH`
    which otherwise build systems would not find.

    If `--env=std` is passed, use the standard `PATH` instead of superenv's.

  * `style` [`--fix`] [`--display-cop-names`] [<var>files</var>|<var>taps</var>|<var>formulae</var>]:
    Check formulae or files for conformance to Homebrew style guidelines.

    <var>formulae</var> and <var>files</var> may not be combined. If both are omitted, style will run
    style checks on the whole Homebrew `Library`, including core code and all
    formulae.

    If `--fix` is passed, style violations will be automatically fixed using
    RuboCop's `--auto-correct` feature.

    If `--display-cop-names` is passed, the RuboCop cop name for each violation
    is included in the output.

    Exits with a non-zero status if any style violations are found.

  * `switch` <var>name</var> <var>version</var>:
    Symlink all of the specific <var>version</var> of <var>name</var>'s install to Homebrew prefix.

  * `tap`:
    List all installed taps.

  * `tap` [`--full`] <var>user</var>`/`<var>repo</var> [<var>URL</var>]:
    Tap a formula repository.

    With <var>URL</var> unspecified, taps a formula repository from GitHub using HTTPS.
    Since so many taps are hosted on GitHub, this command is a shortcut for
    `tap <var>user</var>/<var>repo</var> https://github.com/<var>user</var>/homebrew-<var>repo</var>`.

    With <var>URL</var> specified, taps a formula repository from anywhere, using
    any transport protocol that `git` handles. The one-argument form of `tap`
    simplifies but also limits. This two-argument command makes no
    assumptions, so taps can be cloned from places other than GitHub and
    using protocols other than HTTPS, e.g., SSH, GIT, HTTP, FTP(S), RSYNC.

    By default, the repository is cloned as a shallow copy (`--depth=1`), but
    if `--full` is passed, a full clone will be used. To convert a shallow copy
    to a full copy, you can retap passing `--full` without first untapping.

    `tap` is re-runnable and exits successfully if there's nothing to do.
    However, retapping with a different <var>URL</var> will cause an exception, so first
    `untap` if you need to modify the <var>URL</var>.

  * `tap` `--repair`:
    Migrate tapped formulae from symlink-based to directory-based structure.

  * `tap` `--list-official`:
    List all official taps.

  * `tap` `--list-pinned`:
    List all pinned taps.

  * `tap-info`:
    Display a brief summary of all installed taps.

  * `tap-info` (`--installed`|<var>taps</var>):
    Display detailed information about one or more <var>taps</var>.

    Pass `--installed` to display information on all installed taps.

  * `tap-info` `--json=`<var>version</var> (`--installed`|<var>taps</var>):
    Print a JSON representation of <var>taps</var>. Currently the only accepted value
    for <var>version</var> is `v1`.

    Pass `--installed` to get information on installed taps.

    See the docs for examples of using the JSON output:
    <http://docs.brew.sh/Querying-Brew.html>

  * `tap-pin` <var>tap</var>:
    Pin <var>tap</var>, prioritizing its formulae over core when formula names are supplied
    by the user. See also `tap-unpin`.

  * `tap-unpin` <var>tap</var>:
    Unpin <var>tap</var> so its formulae are no longer prioritized. See also `tap-pin`.

  * `uninstall`, `rm`, `remove` [`--force`] [`--ignore-dependencies`] <var>formula</var>:
    Uninstall <var>formula</var>.

    If `--force` is passed, and there are multiple versions of <var>formula</var>
    installed, delete all installed versions.

    If `--ignore-dependencies` is passed, uninstalling won't fail, even if
    formulae depending on <var>formula</var> would still be installed.

  * `unlink` [`--dry-run`] <var>formula</var>:
    Remove symlinks for <var>formula</var> from the Homebrew prefix. This can be useful
    for temporarily disabling a formula:
    `brew unlink <var>formula</var> && <var>commands</var> && brew link <var>formula</var>`

    If `--dry-run` or `-n` is passed, Homebrew will list all files which would
    be unlinked, but will not actually unlink or delete any files.

  * `unlinkapps` [`--local`] [`--dry-run`] [<var>formulae</var>]:
    Remove symlinks created by `brew linkapps` from `/Applications` (deprecated).

    Unfortunately `brew linkapps` cannot behave nicely with e.g. Spotlight using
    either aliases or symlinks and Homebrew formulae do not build "proper" `.app`
    bundles that can be relocated. Instead, please consider using `brew cask` and
    migrate formulae using `.app`s to casks.

    If no <var>formulae</var> are provided, all linked apps will be removed.

    If provided, `--local` will remove symlinks from the user's `~/Applications`
    directory instead of the system directory.

    If `--dry-run` or `-n` is passed, Homebrew will list all symlinks which
    would be removed, but will not actually delete any files.

  * `unpack` [`--git`|`--patch`] [`--destdir=`<var>path</var>] <var>formulae</var>:
    Unpack the source files for <var>formulae</var> into subdirectories of the current
    working directory. If `--destdir=`<var>path</var> is given, the subdirectories will
    be created in the directory named by <var>path</var> instead.

    If `--patch` is passed, patches for <var>formulae</var> will be applied to the
    unpacked source.

    If `--git` is passed, a Git repository will be initialized in the unpacked
    source. This is useful for creating patches for the software.

  * `unpin` <var>formulae</var>:
    Unpin <var>formulae</var>, allowing them to be upgraded by `brew upgrade`. See also
    `pin`.

  * `untap` <var>tap</var>:
    Remove a tapped repository.

  * `update` [`--merge`] [`--force`]:
    Fetch the newest version of Homebrew and all formulae from GitHub using
    `git`(1) and perform any necessary migrations.

    If `--merge` is specified then `git merge` is used to include updates
    (rather than `git rebase`).

    If `--force` is specified then always do a slower, full update check even
    if unnecessary.

  * `upgrade` [<var>install-options</var>] [`--cleanup`] [`--fetch-HEAD`] [<var>formulae</var>]:
    Upgrade outdated, unpinned brews.

    Options for the `install` command are also valid here.

    If `--cleanup` is specified then remove previously installed <var>formula</var> version(s).

    If `--fetch-HEAD` is passed, fetch the upstream repository to detect if
    the HEAD installation of the formula is outdated. Otherwise, the
    repository's HEAD will be checked for updates when a new stable or devel
    version has been released.

    If <var>formulae</var> are given, upgrade only the specified brews (but do so even
    if they are pinned; see `pin`, `unpin`).

  * `uses` [`--installed`] [`--recursive`] [`--include-build`] [`--include-optional`] [`--skip-recommended`] [`--devel`|`--HEAD`] <var>formulae</var>:
    Show the formulae that specify <var>formulae</var> as a dependency. When given
    multiple formula arguments, show the intersection of formulae that use
    <var>formulae</var>.

    Use `--recursive` to resolve more than one level of dependencies.

    If `--installed` is passed, only list installed formulae.

    By default, `uses` shows all formulae that specify <var>formulae</var> as a required
    or recommended dependency. To include the `:build` type dependencies, pass
    `--include-build`. Similarly, pass `--include-optional` to include `:optional`
    dependencies. To skip `:recommended` type dependencies, pass `--skip-recommended`.

    By default, `uses` shows usages of <var>formulae</var> by stable builds. To find
    cases where <var>formulae</var> is used by development or HEAD build, pass
    `--devel` or `--HEAD`.

  * `--cache`:
    Display Homebrew's download cache. See also `HOMEBREW_CACHE`.

  * `--cache` <var>formula</var>:
    Display the file or directory used to cache <var>formula</var>.

  * `--cellar`:
    Display Homebrew's Cellar path. *Default:* `$(brew --prefix)/Cellar`, or if
    that directory doesn't exist, `$(brew --repository)/Cellar`.

  * `--cellar` <var>formula</var>:
    Display the location in the cellar where <var>formula</var> would be installed,
    without any sort of versioned directory as the last path.

  * `--env`:
    Show a summary of the Homebrew build environment.

  * `--prefix`:
    Display Homebrew's install path. *Default:* `/usr/local`

  * `--prefix` <var>formula</var>:
    Display the location in the cellar where <var>formula</var> is or would be installed.

  * `--repository`:
    Display where Homebrew's `.git` directory is located. For standard installs,
    the `prefix` and `repository` are the same directory.

  * `--repository` <var>user</var>`/`<var>repo</var>:
    Display where tap <var>user</var>`/`<var>repo</var>'s directory is located.

  * `--version`:
    Print the version number of Homebrew to standard output and exit.

## DEVELOPER COMMANDS

  * `audit` [`--strict`] [`--fix`] [`--online`] [`--new-formula`] [`--display-cop-names`] [`--display-filename`] [<var>formulae</var>]:
    Check <var>formulae</var> for Homebrew coding style violations. This should be
    run before submitting a new formula.

    If no <var>formulae</var> are provided, all of them are checked.

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

    `audit` exits with a non-zero status if any errors are found. This is useful,
    for instance, for implementing pre-commit hooks.

  * `bottle` [`--verbose`] [`--no-rebuild`|`--keep-old`] [`--skip-relocation`] [`--root-url=`<var>URL</var>] [`--force-core-tap`] <var>formulae</var>:
    Generate a bottle (binary package) from a formula installed with
    `--build-bottle`.

    If the formula specifies a rebuild version, it will be incremented in the
    generated DSL. Passing `--keep-old` will attempt to keep it at its
    original value, while `--no-rebuild` will remove it.

    If `--verbose` is passed, print the bottling commands and any warnings
    encountered.

    If `--skip-relocation` is passed, do not check if the bottle can be marked
    as relocatable.

    If `--root-url` is passed, use the specified <var>URL</var> as the root of the
    bottle's URL instead of Homebrew's default.

    If `--force-core-tap` is passed, build a bottle even if <var>formula</var> is not
    in homebrew/core or any installed taps.

  * `bottle` `--merge` [`--keep-old`] [`--write` [`--no-commit`]] <var>formulae</var>:
    Generate a bottle from a formula and print the new DSL merged into the
    existing formula.

    If `--write` is passed, write the changes to the formula file. A new
    commit will then be generated unless `--no-commit` is passed.

  * `bump-formula-pr` [`--devel`] [`--dry-run` [`--write`]] [`--audit`|`--strict`] [`--mirror=`<var>URL</var>] [`--version=`<var>version</var>] [`--message=`<var>message</var>] (`--url=`<var>URL</var> `--sha256=`<var>sha-256</var>|`--tag=`<var>tag</var> `--revision=`<var>revision</var>) <var>formula</var>:
    Creates a pull request to update the formula with a new URL or a new tag.

    If a <var>URL</var> is specified, the <var>sha-256</var> checksum of the new download must
    also be specified. A best effort to determine the <var>sha-256</var> and <var>formula</var>
    name will be made if either or both values are not supplied by the user.

    If a <var>tag</var> is specified, the git commit <var>revision</var> corresponding to that
    tag must also be specified.

    If `--devel` is passed, bump the development rather than stable version.
    The development spec must already exist.

    If `--dry-run` is passed, print what would be done rather than doing it.

    If `--write` is passed along with `--dry-run`, perform a not-so-dry run
    making the expected file modifications but not taking any git actions.

    If `--audit` is passed, run `brew audit` before opening the PR.

    If `--strict` is passed, run `brew audit --strict` before opening the PR.

    If `--mirror=`<var>URL</var> is passed, use the value as a mirror URL.

    If `--version=`<var>version</var> is passed, use the value to override the value
    parsed from the URL or tag. Note that `--version=0` can be used to delete
    an existing `version` override from a formula if it has become redundant.

    If `--message=`<var>message</var> is passed, append <var>message</var> to the default PR
    message.

    Note that this command cannot be used to transition a formula from a
    URL-and-sha256 style specification into a tag-and-revision style
    specification, nor vice versa. It must use whichever style specification
    the preexisting formula already uses.

  * `create` <var>URL</var> [`--autotools`|`--cmake`|`--meson`] [`--no-fetch`] [`--set-name` <var>name</var>] [`--set-version` <var>version</var>] [`--tap` <var>user</var>`/`<var>repo</var>]:
    Generate a formula for the downloadable file at <var>URL</var> and open it in the editor.
    Homebrew will attempt to automatically derive the formula name
    and version, but if it fails, you'll have to make your own template. The `wget`
    formula serves as a simple example. For the complete API have a look at
    <http://www.rubydoc.info/github/Homebrew/brew/master/Formula>.

    If `--autotools` is passed, create a basic template for an Autotools-style build.
    If `--cmake` is passed, create a basic template for a CMake-style build.
    If `--meson` is passed, create a basic template for a Meson-style build.

    If `--no-fetch` is passed, Homebrew will not download <var>URL</var> to the cache and
    will thus not add the SHA256 to the formula for you.

    The options `--set-name` and `--set-version` each take an argument and allow
    you to explicitly set the name and version of the package you are creating.

    The option `--tap` takes a tap as its argument and generates the formula in
    the specified tap.

  * `edit`:
    Open all of Homebrew for editing.

  * `edit` <var>formula</var>:
    Open <var>formula</var> in the editor.

  * `formula` <var>formula</var>:
    Display the path where <var>formula</var> is located.

  * `linkage` [`--test`] [`--reverse`]  <var>formula</var>:
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

  * `pull` [`--bottle`] [`--bump`] [`--clean`] [`--ignore-whitespace`] [`--resolve`] [`--branch-okay`] [`--no-pbcopy`] [`--no-publish`] <var>patch-source</var> [<var>patch-source</var>]:
    Gets a patch from a GitHub commit or pull request and applies it to Homebrew.
    Optionally, installs the formulae changed by the patch.

    Each <var>patch-source</var> may be one of:

      ~ The ID number of a PR (pull request) in the homebrew/core GitHub
        repository

      ~ The URL of a PR on GitHub, using either the web page or API URL
        formats. In this form, the PR may be on Homebrew/brew,
        Homebrew/homebrew-core or any tap.

      ~ The URL of a commit on GitHub

      ~ A "https://bot.brew.sh/job/..." string specifying a testing job ID

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

  * `release-notes` [`--markdown`] [<var>previous_tag</var>] [<var>end_ref</var>]:
    Output the merged pull requests on Homebrew/brew between two Git refs.
    If no <var>previous_tag</var> is provided it defaults to the newest tag.
    If no <var>end_ref</var> is provided it defaults to `origin/master`.

    If `--markdown` is passed, output as a Markdown list.

  * `tap-new` <var>user</var>`/`<var>repo</var>:
    Generate the template files for a new tap.

  * `test` [`--devel`|`--HEAD`] [`--debug`] [`--keep-tmp`] <var>formula</var>:
    Most formulae provide a test method. `brew test` <var>formula</var> runs this
    test method. There is no standard output or return code, but it should
    generally indicate to the user if something is wrong with the installed
    formula.

    To test the development or head version of a formula, use `--devel` or
    `--HEAD`.

    If `--debug` is passed and the test fails, an interactive debugger will be
    launched with access to IRB or a shell inside the temporary test directory.

    If `--keep-tmp` is passed, the temporary files created for the test are
    not deleted.

    Example: `brew install jruby && brew test jruby`

  * `tests` [`--verbose`] [`--coverage`] [`--generic`] [`--no-compat`] [`--only=`<var>test_script</var>[`:`<var>line_number</var>]] [`--seed` <var>seed</var>] [`--online`] [`--official-cmd-taps`]:
    Run Homebrew's unit and integration tests. If provided,
    `--only=`<var>test_script</var> runs only <var>test_script</var>_spec.rb, and `--seed`
    randomizes tests with the provided value instead of a random seed.

    If `--verbose` is passed, print the command that runs the tests.

    If `--coverage` is passed, also generate code coverage reports.

    If `--generic` is passed, only run OS-agnostic tests.

    If `--no-compat` is passed, do not load the compatibility layer when
    running tests.

    If `--online` is passed, include tests that use the GitHub API.

    If `--official-cmd-taps` is passed, include tests that use any of the
    taps for official external commands.

  * `update-test` [`--commit=`<var>commit</var>] [`--before=`<var>date</var>] [`--to-tag`] [`--keep-tmp`]:
    Runs a test of `brew update` with a new repository clone.

    If no arguments are passed, use `origin/master` as the start commit.

    If `--commit=`<var>commit</var> is passed, use <var>commit</var> as the start commit.

    If `--before=`<var>date</var> is passed, use the commit at <var>date</var> as the
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
scripts that reside somewhere in the `PATH`, named `brew-`<var>cmdname</var> or
`brew-`<var>cmdname</var>`.rb`, which can be invoked like `brew` <var>cmdname</var>. This allows you
to create your own commands without modifying Homebrew's internals.

Instructions for creating your own commands can be found in the docs:
<http://docs.brew.sh/External-Commands.html>

## SPECIFYING FORMULAE

Many Homebrew commands accept one or more <var>formula</var> arguments. These arguments
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

  * `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`:
    When using the `S3` download strategy, Homebrew will look in
    these variables for access credentials (see
    <https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html#cli-environment>
    to retrieve these access credentials from AWS).  If they are not set,
    the `S3` download strategy will download with a public
    (unsigned) URL.

  * `BROWSER`:
    If set, and `HOMEBREW_BROWSER` is not, use `BROWSER` as the web browser
    when opening project homepages.

  * `EDITOR`:
    If set, and `HOMEBREW_EDITOR` and `VISUAL` are not, use `EDITOR` as the text editor.

  * `GIT`:
    When using Git, Homebrew will use `GIT` if set,
    a Homebrew-built Git if installed, or the system-provided binary.

    Set this to force Homebrew to use a particular git binary.

  * `HOMEBREW_BOTTLE_DOMAIN`:
    If set, instructs Homebrew to use the given URL as a download mirror for bottles.

  * `HOMEBREW_ARTIFACT_DOMAIN`:
    If set, instructs Homebrew to use the given URL as a download mirror for bottles and binaries.

  * `HOMEBREW_AUTO_UPDATE_SECS`:
    If set, Homebrew will only check for autoupdates once per this seconds interval.

    *Default:* `60`.

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
    If set, Homebrew will not send analytics. See: <http://docs.brew.sh/Analytics.html>

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

  * `VISUAL`:
    If set, and `HOMEBREW_EDITOR` is not, use `VISUAL` as the text editor.

## USING HOMEBREW BEHIND A PROXY

Homebrew uses several commands for downloading files (e.g. `curl`, `git`, `svn`).
Many of these tools can download via a proxy. It's common for these tools
to read proxy parameters from environment variables.

For the majority of cases setting `http_proxy` is enough. You can set this in
your shell profile, or you can use it before a brew command:

    http_proxy=http://<var>host</var>:<var>port</var> brew install foo

If your proxy requires authentication:

    http_proxy=http://<var>user</var>:<var>password</var>@<var>host</var>:<var>port</var> brew install foo

## SEE ALSO

Homebrew Documentation: <https://github.com/Homebrew/brew/blob/master/docs/>

`brew-cask`(1), `git`(1), `git-log`(1)

## AUTHORS

Homebrew's lead maintainer is Mike McQuaid.

Homebrew's current maintainers are Alyssa Ross, Andrew Janke, Baptiste Fontaine, Alex Dunn, FX Coudert, ilovezfs, Josh Hagins, JCount, Misty De Meo, neutric, Tomasz Pajor, Markus Reiter, Tim Smith, Tom Schoonjans, Uladzislau Shablinski and William Woodruff.

Former maintainers with significant contributions include Xu Cheng, Martin Afanasjew, Dominyk Tiller, Brett Koonce, Jack Nagel, Adam Vandenberg and Homebrew's creator: Max Howell.

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
