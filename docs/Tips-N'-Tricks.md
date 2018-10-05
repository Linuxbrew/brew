# Tips and Tricks

## Installing previous versions of formulae

The supported method of installing specific versions of
some formulae is to see if there is a versioned formula (e.g. `gcc@6`) available. If the version you’re looking for isn’t available, consider using `brew extract`.

### Installing directly from pull requests
You can [browse pull requests](https://github.com/Homebrew/homebrew-core/pulls)
and install through their direct link. For example, Python 3.7.0 from pull request [Homebrew/homebrew-core#29490](https://github.com/Homebrew/homebrew-core/pull/29490):

```sh
brew install https://raw.githubusercontent.com/sashkab/homebrew-core/176823eb82ee1b5ce55a91e5e1bf2f50aa674092/Formula/python.rb
```

## Quickly remove something from `/usr/local`

```sh
brew unlink <formula>
```

This can be useful if a package can't build against the version of something you have linked into `/usr/local`.

And of course, you can simply `brew link <formula>` again afterwards!

## Activate a previously installed version of a formula

```sh
brew info <formula>
brew switch <formula> <version>
```

Use `brew info <formula>` to check what versions are installed but not currently activated, then `brew switch <formula> <version>` to activate the desired version. This can be useful if you would like to switch between versions of a formula.

## Install into Homebrew without formulae

```sh
./configure --prefix=/usr/local/Cellar/foo/1.2 && make && make install && brew link foo
```

## Pre-downloading a file for a formula
Sometimes it's faster to download a file via means other than those
strategies that are available as part of Homebrew. For example,
Erlang provides a torrent that'll let you download at 4–5× the normal
HTTP method.

Download the file and drop it in `~/Library/Caches/Homebrew`, but
watch the file name. Homebrew downloads files as `<formula>-<version>`.
In the case of Erlang, this requires renaming the file from `otp_src_R13B03` to
`erlang-R13B03`.

`brew --cache -s erlang` will print the correct name of the cached
download. This means instead of manually renaming a formula, you can
run `mv the_tarball $(brew --cache -s <formula>)`.

You can also pre-cache the download by using the command `brew fetch <formula>` which also displays the SHA-256 hash. This can be useful for updating formulae to new versions.

## Installing stuff without the Xcode CLT

```sh
brew sh          # or: eval $(brew --env)
gem install ronn # or c-programs
```

This imports the `brew` environment into your existing shell; `gem` will pick up the environment variables and be able to build. As a bonus `brew`'s automatically determined optimization flags are set.

## Install only a formula's dependencies (not the formula)

```sh
brew install --only-dependencies <formula>
```

## Interactive Homebrew Shell

```sh
$ brew irb
1.8.7 :001 > Formula.factory("ace").methods - Object.methods
 => [:install, :path, :homepage, :downloader, :stable, :bottle, :devel, :head, :active_spec, :buildpath, :ensure_specs_set, :url, :version, :specs, :mirrors, :installed?, :explicitly_requested?, :linked_keg, :installed_prefix, :prefix, :rack, :bin, :doc, :include, :info, :lib, :libexec, :man, :man1, :man2, :man3, :man4, :man5, :man6, :man7, :man8, :sbin, :share, :etc, :var, :plist_name, :plist_path, :download_strategy, :cached_download, :caveats, :options, :patches, :keg_only?, :fails_with?, :skip_clean?, :brew, :std_cmake_args, :deps, :external_deps, :recursive_deps, :system, :fetch, :verify_download_integrity, :fails_with_llvm, :fails_with_llvm?, :std_cmake_parameters, :mkdir, :mktemp]
1.8.7 :002 >
```

## Hiding the beer mug emoji when finishing a build

```sh
export HOMEBREW_NO_EMOJI=1
```

This sets the `HOMEBREW_NO_EMOJI` environment variable, causing Homebrew
to hide all emoji.

The beer emoji can also be replaced with other character(s):

```sh
export HOMEBREW_INSTALL_BADGE="☕️ 🐸"
```

## Editor plugins

### Sublime Text

In Sublime Text 2/3, you can use Package Control to install
[Homebrew-formula-syntax](https://github.com/samueljohn/Homebrew-formula-syntax),
which adds highlighting for inline patches.

### Vim
[brew.vim](https://github.com/xu-cheng/brew.vim) adds highlighting to
inline patches in Vim.

### Emacs
[homebrew-mode](https://github.com/dunn/homebrew-mode) provides syntax
highlighting for inline patches as well as a number of helper functions
for editing formula files.

[pcmpl-homebrew](https://github.com/hiddenlotus/pcmpl-homebrew) provides completion
for emacs shell-mode and eshell-mode.

### Atom
[language-homebrew-formula](https://atom.io/packages/language-homebrew-formula)
adds highlighting and diff support (with the
[language-diff](https://atom.io/packages/language-diff) plugin).
