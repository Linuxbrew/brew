# Common Issues

This is a list of commonly encountered problems, known issues, and their solutions.

### `brew` complains about absence of "Command Line Tools"
You need to have the Xcode Command Line Utilities installed (and updated): run `xcode-select --install` in the terminal.
(In OS X prior to 10.9, the "Command Line Tools" package can alternatively be installed from within Xcode. `⌘,` will get you to preferences. Visit the "Downloads" tab and hit the install button next to "Command Line Tools".)

### Ruby: `bad interpreter: /usr/bin/ruby^M: no such file or directory`
You cloned with `git`, and your Git configuration is set to use Windows line endings. See this page: <https://help.github.com/articles/dealing-with-line-endings>

### Ruby: `bad interpreter: /usr/bin/ruby`
You don't have a `/usr/bin/ruby` or it is not executable. It's not recommended to let this persist; you'd be surprised how many `.app`s, tools and scripts expect your macOS-provided files and directories to be *unmodified* since macOS was installed.

### `brew update` complains about untracked working tree files
After running `brew update`, you receive a Git error warning about untracked files or local changes that would be overwritten by a checkout or merge, followed by a list of files inside your Homebrew installation.

This is caused by an old bug in in the `update` code that has long since been fixed. However, the nature of the bug requires that you do the following:

```sh
cd $(brew --repository)
git reset --hard FETCH_HEAD
```

If `brew doctor` still complains about uncommitted modifications, also run this command:

```sh
cd $(brew --repository)/Library
git clean -fd
```

### Ruby: `invalid multibyte escape: /^\037\213/`

You see an error similar to:

```
Error: /usr/local/Library/Homebrew/download_strategy.rb:84: invalid multibyte escape: /^\037\213/
invalid multibyte escape: /^\037\235/
```

In the past, Homebrew assumed that `/usr/bin/ruby` was Ruby 1.8. On OS X 10.9, it is now Ruby 2.0. There are various incompatibilities between the two versions, so if you upgrade to OS X 10.9 while using a sufficiently old version of Homebrew, you will encounter errors.

The incompatibilities have been addressed in more recent versions of Homebrew, and instead of making assumptions about `/usr/bin/ruby`, it uses the executable inside macOS's Ruby framework or a vendored Ruby.

To recover from this situation, do the following:

```sh
cd $(brew --prefix)
git fetch origin
git reset --hard FETCH_HEAD
brew update
```

### `launchctl` refuses to load launchd plist files
When trying to load a plist file into launchctl, you receive an error that resembles

```
Bug: launchctl.c:2325 (23930):13: (dbfd = open(g_job_overrides_db_path, [...]
launch_msg(): Socket is not connected
```

or

```
Could not open job overrides database at: /private/var/db/launchd.db/com.apple.launchd/overrides.plist: 13: Permission denied
launch_msg(): Socket is not connected
```

These are likely due to one of four issues:

1. You are using iTerm. The solution is to use Terminal.app when interacting with `launchctl`.
2. You are using a terminal multiplexer such as `tmux` or `screen`. You should interact with `launchctl` from a separate Terminal.app shell.
3. You are attempting to run `launchctl` while logged in remotely. You should enable screen sharing on the remote machine and issue the command using Terminal.app running on that machine.
4. You are `su`'ed as a different user.

### `brew upgrade` errors out
When running `brew upgrade`, you see something like this:

```
$ brew upgrade
Error: undefined method `include?' for nil:NilClass
Please report this bug:
    https://docs.brew.sh/Troubleshooting
/usr/local/Library/Homebrew/formula.rb:393:in `canonical_name'
/usr/local/Library/Homebrew/formula.rb:425:in `factory'
/usr/local/Library/Contributions/examples/brew-upgrade.rb:7
/usr/local/Library/Contributions/examples/brew-upgrade.rb:7:in `map'
/usr/local/Library/Contributions/examples/brew-upgrade.rb:7
/usr/local/bin/brew:46:in `require'
/usr/local/bin/brew:46:in `require?'
/usr/local/bin/brew:79
```

This happens because an old version of the upgrade command is hanging around for some reason. The fix:

```sh
cd $(brew --repository)/Library/Contributions/examples
git clean -n # if this doesn't list anything that you want to keep, then
git clean -f # this will remove untracked files
```

### Python: `easy-install.pth` cannot be linked

```
Warning: Could not link <formula>. Unlinking...
Error: The `brew link` step did not complete successfully
The formula built, but is not symlinked into /usr/local
You can try again using `brew link <formula>'

Possible conflicting files are:
/usr/local/lib/python2.7/site-packages/site.py
/usr/local/lib/python2.7/site-packages/easy-install.pth
==> Could not symlink file: /homebrew/Cellar/<formula>/<version>/lib/python2.7/site-packages/site.py
Target /usr/local/lib/python2.7/site-packages/site.py already exists. You may need to delete it.
To force the link and overwrite all other conflicting files, do:
  brew link --overwrite formula_name

To list all files that would be deleted:
  brew link --overwrite --dry-run formula_name
```

Don't follow the advice here but fix by using
`Language::Python.setup_install_args` in the formula as described in
[Python for Formula Authors](Python-for-Formula-Authors.md).

### Upgrading macOS

Upgrading macOS can cause errors like the following:

- `dyld: Library not loaded: /usr/local/opt/icu4c/lib/libicui18n.54.dylib`
- `configure: error: Cannot find libz`

Following a macOS upgrade it may be necessary to reinstall the Xcode Command Line Tools and `brew upgrade` all installed formula:

```sh
xcode-select --install
brew upgrade
```
