![Linuxbrew logo](https://linuxbrew.sh/images/linuxbrew-256x256.png)

# Linuxbrew has been merged into Homebrew

Linuxbrew/brew has been merged into [Homebrew/brew](https://github.com/Homebrew/brew)! Existing installations of Linuxbrew will be automatically migrated to Homebrew. Linuxbrew/brew will no longer be updated. See the [Homebrew documentation of Linuxbrew](https://docs.brew.sh/Linuxbrew) and the Homebrew 2.0.0 [blog post](https://brew.sh/2019/02/02/homebrew-2.0.0/).

> Homebrew officially supports Linux and Windows 10 with Windows Subsystem for Linux (WSL). “Homebrew on Linux” is called “Linuxbrew”. You can install it in your home directory, so it does not require sudo, and use it to install software that your host distribution’s package manager does not provide. Linuxbrew uses its own repository for formulae: [Linuxbrew/homebrew-core](https://github.com/Linuxbrew/homebrew-core).

# Linuxbrew

[![GitHub release](https://img.shields.io/github/tag/Linuxbrew/brew.svg)](https://github.com/Linuxbrew/brew/releases)

The Homebrew package manager may be used on Linux and Windows 10, using [Windows Subsystem for Linux (WSL)](https://docs.microsoft.com/en-us/windows/wsl/about). Homebrew is referred to as Linuxbrew when running on Linux or Windows. It can be installed in your home directory, in which case it does not use *sudo*. Linuxbrew does not use any libraries provided by your host system, except *glibc* and *gcc* if they are new enough. Linuxbrew can install its own current versions of *glibc* and *gcc* for older distribution of Linux.

[Features](#features), [dependencies](#dependencies) and [installation instructions](#install) are described below. Terminology (e.g. the difference between a Cellar, Tap, Cask and so forth) is [explained in the documentation](Formula-Cookbook.md#homebrew-terminology).

## Features

+ Can install software to your home directory and so does not require *sudo*
+ Install software not packaged by your host distribution
+ Install up-to-date versions of software when your host distribution is old
+ Use the same package manager to manage your macOS, Linux, and Windows systems

## Install

Paste at a terminal prompt:

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/Linuxbrew/install/master/install.sh)"
```

The installation script installs Linuxbrew to `/home/linuxbrew/.linuxbrew` using *sudo* if possible and in your home directory at `~/.linuxbrew` otherwise. Linuxbrew does not use *sudo* after installation. Using `/home/linuxbrew/.linuxbrew` allows the use of more binary packages (bottles) than installing in your personal home directory.

Follow the *Next steps* instructions to add Linuxbrew to your `PATH` and to your bash shell profile script, either `~/.profile` on Debian/Ubuntu or `~/.bash_profile` on CentOS/Fedora/RedHat.

```sh
test -d ~/.linuxbrew && eval $(~/.linuxbrew/bin/brew shellenv)
test -d /home/linuxbrew/.linuxbrew && eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)
test -r ~/.bash_profile && echo "eval \$($(brew --prefix)/bin/brew shellenv)" >>~/.bash_profile
echo "eval \$($(brew --prefix)/bin/brew shellenv)" >>~/.profile
```

You're done! Try installing a package:

```sh
brew install hello
```

If you're using an older distribution of Linux, installing your first package will also install a recent version of `glibc` and `gcc`. Use `brew doctor` to troubleshoot common issues.

## Dependencies

+ **GCC** 4.4 or newer
+ **Linux** 2.6.32 or newer
+ **Glibc** 2.12 or newer
+ **64-bit x86** CPU

Paste at a terminal prompt:

### Debian or Ubuntu

```sh
sudo apt-get install build-essential curl file git
```

### Fedora, CentOS, or Red Hat

```sh
sudo yum groupinstall 'Development Tools' && sudo yum install curl file git
```

### Raspberry Pi

Linuxbrew can run on Raspberry Pi (32-bit ARM), but no binary packages (bottles) are available. Support for Raspberry Pi is on a best-effort basis. Pull requests are welcome to improve the experience on Raspberry Pi.

### 32-bit x86

Linuxbrew does not currently support 32-bit x86 platforms. It would be possible for Linuxbrew to work on 32-bit x86 platforms with some effort. An interested and dedicated person could maintain a fork of Homebrew to develop support for 32-bit x86.

## Alternative Installation

Extract or `git clone` Linuxbrew wherever you want. Use `/home/linuxbrew/.linuxbrew` if possible.

```sh
git clone https://github.com/Homebrew/brew ~/.linuxbrew/Homebrew
mkdir ~/.linuxbrew/bin
ln -s ../Homebrew/bin/brew ~/.linuxbrew/bin
eval $(~/.linuxbrew/bin/brew shellenv)
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

## Who Are You (Linuxbrew)?

Linuxbrew's lead maintainer is [Shaun Jackman](https://sjackman.ca).

Linuxbrew/homebrew-core's lead maintainer is [Michka Popoff](https://github.com/iMichka).

Linuxbrew's other current maintainers are [Piotr Gaczkowski](https://github.com/DoomHammer), [Maxim Belkin](https://github.com/maxim-belkin), [Jonathan Chang](https://github.com/jonchang), and [Alyssa Ross](https://github.com/alyssais).

Former Linuxbrew maintainers with significant contributions include [Bob W. Hogg](https://github.com/rwhogg).

## Who Are You (Homebrew)?
Homebrew's lead maintainer is [Mike McQuaid](https://github.com/mikemcquaid).

Homebrew's project leadership committee is [Mike McQuaid](https://github.com/mikemcquaid), [Misty De Meo](https://github.com/mistydemeo) and [Markus Reiter](https://github.com/reitermarkus).

Homebrew/brew's other current maintainers are [Claudia Pellegrino](https://github.com/claui), [Michka Popoff](https://github.com/imichka), [Shaun Jackman](https://github.com/sjackman), [Chongyu Zhu](https://github.com/lembacon), [Vitor Galvao](https://github.com/vitorgalvao), [Misty De Meo](https://github.com/mistydemeo), [Gautham Goli](https://github.com/GauthamGoli), [Markus Reiter](https://github.com/reitermarkus), [Steven Peters](https://github.com/scpeters), [Jonathan Chang](https://github.com/jonchang) and [William Woodruff](https://github.com/woodruffw).

Homebrew/brew's Linux support (and Linuxbrew) maintainers are [Michka Popoff](https://github.com/imichka) and [Shaun Jackman](https://github.com/sjackman).

Homebrew/homebrew-core's other current maintainers are [Claudia Pellegrino](https://github.com/claui), [Igor Kapkov](https://github.com/igas), [Michka Popoff](https://github.com/imichka), [Shaun Jackman](https://github.com/sjackman), [Chongyu Zhu](https://github.com/lembacon), [Izaak Beekman](https://github.com/zbeekman), [Sean Molenaar](https://github.com/SMillerDev), [Jan Viljanen](https://github.com/javian), [Jason Tedor](https://github.com/jasontedor), [Viktor Szakats](https://github.com/vszakats), [FX Coudert](https://github.com/fxcoudert), [Thierry Moisan](https://github.com/moisan), [Steven Peters](https://github.com/scpeters), [Misty De Meo](https://github.com/mistydemeo) and [Tom Schoonjans](https://github.com/tschoonj).

Former maintainers with significant contributions include [JCount](https://github.com/jcount), [commitay](https://github.com/commitay), [Dominyk Tiller](https://github.com/DomT4), [Tim Smith](https://github.com/tdsmith), [Baptiste Fontaine](https://github.com/bfontaine), [Xu Cheng](https://github.com/xu-cheng), [Martin Afanasjew](https://github.com/UniqMartin), [Brett Koonce](https://github.com/asparagui), [Charlie Sharpsteen](https://github.com/Sharpie), [Jack Nagel](https://github.com/jacknagel), [Adam Vandenberg](https://github.com/adamv), [Andrew Janke](https://github.com/apjanke), [Alex Dunn](https://github.com/dunn), [neutric](https://github.com/neutric), [Tomasz Pajor](https://github.com/nijikon), [Uladzislau Shablinski](https://github.com/vladshablinsky), [Alyssa Ross](https://github.com/alyssais), [ilovezfs](https://github.com/ilovezfs) and Homebrew's creator: [Max Howell](https://github.com/mxcl).

## Linuxbrew Community

- [@Linuxbrew on Twitter](https://twitter.com/Linuxbrew)
- [Linuxbrew/core on GitHub](https://github.com/Linuxbrew/homebrew-core)
- [Linuxbrew category](https://discourse.brew.sh/c/linuxbrew) of [Homebrew's Discourse](https://discourse.brew.sh)

## License
Code is under the [BSD 2-clause "Simplified" License](LICENSE.txt).
Documentation is under the [Creative Commons Attribution license](https://creativecommons.org/licenses/by/4.0/).

## Donations

Linuxbrew is a non-profit project run entirely by unpaid volunteers. We need your funds to pay for continuous integration and the computer resources used to build precompiled binary bottles of your favourite formulae. Every donation will be spent on making Linuxbrew better for our users.

Please consider [donating regularly to Linuxbrew through Patreon](https://www.patreon.com/linuxbrew). We appreciate your support and contribution, no matter the level.

[![Donate with Patreon](https://img.shields.io/badge/Patreon-Linuxbrew-green.svg)](https://www.patreon.com/linuxbrew)

[Linuxbrew](https://linuxbrew.sh) is a fork of [Homebrew](https://brew.sh), the macOS package manager, for Linux. Please consider [donating to Homebrew](https://github.com/Homebrew/brew#donations) as well if you use Homebrew on macOS.

[![Donate with Patreon](https://img.shields.io/badge/Patreon-Homebrew-green.svg)](https://www.patreon.com/homebrew)

## Sponsors

Our binary packages (bottles) are built on [CircleCI](https://circleci.com/) and hosted by [Bintray](https://bintray.com/linuxbrew).

[<img alt="CircleCI logo" style="height:1in" src="https://assets.brandfolder.com/otz6k5-cj8pew-e4rk9u/original/circle-logo-horizontal-black.png">](https://circleci.com/)

[![Downloads by Bintray](https://bintray.com/docs/images/downloads_by_bintray_96.png)](https://bintray.com/linuxbrew)
