![Linuxbrew logo](http://linuxbrew.sh/images/linuxbrew-256x256.png)

# Linuxbrew
[![GitHub release](https://img.shields.io/github/tag/Linuxbrew/brew.svg)](https://github.com/Linuxbrew/brew/releases)

[Linuxbrew](http://linuxbrew.sh) is a fork of [Homebrew](http://brew.sh), the macOS package manager, for Linux.

It can be installed in your home directory and does not require root access. The same package manager can be used on both your Linux server and your Mac laptop. Installing a modern version of *glibc* and *gcc* in your home directory on an old distribution of Linux takes five minutes.

[Features](http://linuxbrew.sh#features), usage and installation instructions are [summarised on the homepage](http://linuxbrew.sh). Terminology (e.g. the difference between a Cellar, Tap, Cask and so forth) is [explained here](https://docs.brew.sh/Formula-Cookbook#homebrew-terminology).

To receive updates of major changes to Linuxbrew subscribe to the [Linuxbrew Updates](https://github.com/Linuxbrew/brew/issues/1) issue on GitHub.

## Install Linuxbrew

The installation script installs Linuxbrew to `/home/linuxbrew/.linuxbrew` if possible and in your home directory at `~/.linuxbrew` otherwise.

Paste at a Terminal prompt:

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/Linuxbrew/install/master/install.sh)"
```

Follow the *Next steps* instructions to add Linuxbrew to your `PATH` and to your bash shell profile script, either `~/.profile` on Debian/Ubuntu or `~/.bash_profile` on CentOS/Fedora/RedHat.

```sh
test -d ~/.linuxbrew && PATH="$HOME/.linuxbrew/bin:$HOME/.linuxbrew/sbin:$PATH"
test -d /home/linuxbrew/.linuxbrew && PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:$PATH"
test -r ~/.bash_profile && echo "export PATH='$(brew --prefix)/bin:$(brew --prefix)/sbin'":'"$PATH"' >>~/.bash_profile
echo "export PATH='$(brew --prefix)/bin:$(brew --prefix)/sbin'":'"$PATH"' >>~/.profile
```

You're done! Try installing a package:

```sh
brew install hello
```

If you're using an older distribution of Linux, installing your first package will also install a recent version of `gcc`.

Use `brew doctor` to troubleshoot common issues.

Features
--------

+ Can install software to a home directory and so does not require sudo
+ Install software not packaged by the native distribution
+ Install up-to-date versions of software when the native distribution is old
+ Use the same package manager to manage both your Mac and Linux machines

Dependencies
------------

+ **GCC** 4.4 or newer
+ **Linux** 2.6.16 or newer
+ **Glibc** 2.12 or newer (2.19 or newer to be able to use bottles)
+ **64-bit x86** or **32-bit ARM** (Raspberry Pi)

Paste at a Terminal prompt:

### Debian or Ubuntu

```sh
sudo apt-get install build-essential curl file git
```

### Fedora

```sh
sudo dnf groupinstall 'Development Tools' && sudo dnf install curl file git
```

### CentOS or Red Hat

```sh
sudo yum groupinstall 'Development Tools' && sudo yum install curl file git
```

### 32-bit x86 platforms

Linuxbrew does not currently support 32-bit x86 platforms. It would be possible for Linuxbrew to work on 32-bit x86 platforms with some effort. Pull requests would be welcome if someone were to volunteer to maintain the 32-bit x86 support.

Bottles
-------

Bottles are Linuxbrew's precompiled binary packages. Linuxbrew bottles work on any Linux system. They do however require `glibc` 2.19 or better. On systems with an older version of `glibc` (at least 2.12), Linuxbrew will install `glibc` the first time that you install a bottled formula. If you prefer to use the `glibc` provided by your system and build all formulas from source, add to your `.bashrc` or `.zshrc`:

`export HOMEBREW_BUILD_FROM_SOURCE=1`

## Alternative Installation

Extract (or `git clone`) Linuxbrew wherever you want. Use `/home/linuxbrew/.linuxbrew` if possible.

```sh
git clone https://github.com/Linuxbrew/brew.git ~/.linuxbrew
```

```sh
PATH="$HOME/.linuxbrew/bin:$PATH"
export MANPATH="$(brew --prefix)/share/man:$MANPATH"
export INFOPATH="$(brew --prefix)/share/info:$INFOPATH"
```

## What Packages Are Available?
1. Type `brew search` for a list.
2. Or visit [formulae.brew.sh](https://formulae.brew.sh) to browse packages online.
3. Or use `brew search --desc <keyword>` to browse packages from the command line.

## More Documentation
`brew help`, `man brew` or check [our documentation](https://github.com/Linuxbrew/brew/tree/master/docs#readme).

## Troubleshooting
First, please run `brew update` and `brew doctor`.

Second, read the [Troubleshooting Checklist](https://docs.brew.sh/Troubleshooting).

**If you don't read these it will take us far longer to help you with your problem.**

## Contributing

We'd love you to contribute to Linuxbrew. First, please read our [Contribution Guide](CONTRIBUTING.md) and [Code of Conduct](CODE_OF_CONDUCT.md#code-of-conduct). Please see our [guidelines](CONTRIBUTING.md#contributing-to-linuxbrew) on whether to send pull requests to Linuxbrew or Homebrew.

We explicitly welcome contributions from people who have never contributed to open-source before: we were all beginners once! We can help build on a partially working pull request with the aim of getting it merged. We are also actively seeking to diversify our contributors and especially welcome contributions from women from all backgrounds and people of colour.

A good starting point for contributing is running `brew audit --strict` with some of the packages you use (e.g. `brew audit --strict wget` if you use `wget`) and then read through the warnings, try to fix them until `brew audit --strict` shows no results and [submit a pull request](https://docs.brew.sh/How-To-Open-a-Homebrew-Pull-Request). If no formulae you use have warnings you can run `brew audit --strict` without arguments to have it run on all packages and pick one.

Alternatively, for something more substantial, check out one of the issues labeled `help wanted` in [Homebrew/brew](https://github.com/homebrew/brew/issues?q=is%3Aopen+is%3Aissue+label%3A%22help+wanted%22) or [Homebrew/homebrew-core](https://github.com/homebrew/homebrew-core/issues?q=is%3Aopen+is%3Aissue+label%3A%22help+wanted%22).

Good luck!

## Security
Please report security issues to our [HackerOne](https://hackerone.com/homebrew/).

## Who Are You?

Linuxbrew's lead maintainer is [Shaun Jackman](http://sjackman.ca).

Linuxbrew/homebrew-core's lead maintainer is [Michka Popoff](https://github.com/iMichka).

Linuxbrew's other current maintainers are [Piotr Gaczkowski](https://github.com/DoomHammer), [Maxim Belkin](https://github.com/maxim-belkin), [Jonathan Chang](https://github.com/jonchang), and [Alyssa Ross](https://github.com/alyssais).

Linuxbrew/homebrew-core's other current maintainers are [Shaun Jackman](http://sjackman.ca).

Former maintainers with significant contributions include [Bob W. Hogg](https://github.com/rwhogg).

## Linuxbrew Community
- [@Linuxbrew (Twitter)](https://twitter.com/Linuxbrew)

## License
Code is under the [BSD 2-clause "Simplified" License](LICENSE.txt).
Documentation is under the [Creative Commons Attribution license](https://creativecommons.org/licenses/by/4.0/).

## Donations

Linuxbrew is a non-profit project run entirely by unpaid volunteers. We need your funds to pay for continuous integration and the computer resources used to build precompiled binary bottles of your favourite formulae. Every donation will be spent on making Linuxbrew better for our users.

Please consider [donating regularly to Linuxbrew through Patreon](https://www.patreon.com/linuxbrew). We appreciate your support and contribution, no matter the level.

[![Donate with Patreon](https://img.shields.io/badge/Patreon-Linuxbrew-green.svg)](https://www.patreon.com/linuxbrew)

[Linuxbrew](http://linuxbrew.sh) is a fork of [Homebrew](http://brew.sh), the macOS package manager, for Linux. Please consider [donating to Homebrew](https://github.com/Homebrew/brew#donations) as well if you use Homebrew on macOS.

[![Donate with Patreon](https://img.shields.io/badge/Patreon-Homebrew-green.svg)](https://www.patreon.com/homebrew)

# Sponsors

Our bottles (binary packages) are built on [CircleCI](https://circleci.com/).

[<img alt="CircleCI logo" style="height:1in" src="https://assets.brandfolder.com/otz6k5-cj8pew-e4rk9u/original/circle-logo-horizontal-black.png">](https://circleci.com/)

Our bottles (binary packages) are hosted by [Bintray](https://bintray.com/linuxbrew).

[![Downloads by Bintray](https://bintray.com/docs/images/downloads_by_bintray_96.png)](https://bintray.com/linuxbrew)
