![Linuxbrew logo](https://linuxbrew.sh/images/linuxbrew-256x256.png)

# Linuxbrew

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

## Linuxbrew Community

- [@Linuxbrew on Twitter](https://twitter.com/Linuxbrew)
- [Linuxbrew/core on GitHub](https://github.com/Linuxbrew/homebrew-core)
- [Linuxbrew category](https://discourse.brew.sh/c/linuxbrew) of [Homebrew's Discourse](https://discourse.brew.sh)

## Sponsors

Our binary packages (bottles) are built on [CircleCI](https://circleci.com/) and hosted by [Bintray](https://bintray.com/linuxbrew).

[<img alt="CircleCI logo" style="height:1in" src="https://assets.brandfolder.com/otz6k5-cj8pew-e4rk9u/original/circle-logo-horizontal-black.png">](https://circleci.com/)

[![Downloads by Bintray](https://bintray.com/docs/images/downloads_by_bintray_96.png)](https://bintray.com/linuxbrew)
