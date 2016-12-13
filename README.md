![Linuxbrew logo](http://linuxbrew.sh/images/linuxbrew-256x256.png)

# Linuxbrew

[Linuxbrew](http://linuxbrew.sh) is a fork of [Homebrew](http://brew.sh), the Mac OS package manager, for Linux.

It can be installed in your home directory and does not require root access. The same package manager can be used on both your Linux server and your Mac laptop. Installing a modern version of *glibc* and *gcc* in your home directory on an old distribution of Linux takes five minutes.

Features, usage and installation instructions are [summarised on the homepage](http://linuxbrew.sh). Terminology (e.g. the difference between a Cellar, Tap, Cask and so forth) is [explained here](docs/Formula-Cookbook.md#homebrew-terminology).

To receive updates of major changes to Linuxbrew subscribe to the [Linuxbrew Updates](https://github.com/Linuxbrew/brew/issues/1) issue on GitHub.

Install Linuxbrew (tl;dr)
-------------------------

Paste at a Terminal prompt:

```sh
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Linuxbrew/install/master/install)"
PATH="$HOME/.linuxbrew/bin:$PATH"
```

Edit your `~/.bash_profile` to add `~/.linuxbrew/bin` to your `PATH`:

```sh
echo 'export PATH="$HOME/.linuxbrew/bin:$PATH"' >>~/.bash_profile
```

You're done! Try installing a package:

```sh
brew install hello
```

Use `brew doctor` to troubleshoot common issues.

See [Dependencies](#dependencies) and [Installation](#installation) below for more details.

Features
--------

+ Can install software to a home directory and so does not require sudo
+ Install software not packaged by the native distribution
+ Install up-to-date versions of software when the native distribution is old
+ Use the same package manager to manage both your Mac and Linux machines

Dependencies
------------

* **Ruby** 1.8.6 or newer
+ **GCC** 4.4 or newer
+ **Linux** 2.6.16 or newer
+ **64-bit x86** or **32-bit ARM** (Raspberry Pi)

Paste at a Terminal prompt:

### Debian or Ubuntu

```sh
sudo apt-get install build-essential curl git python-setuptools ruby
```

### Fedora, CentOS or Red Hat

```sh
sudo yum groupinstall 'Development Tools' && sudo yum install curl git irb python-setuptools ruby
```

### 32-bit x86 platforms

Linuxbrew does not currently support 32-bit x86 platforms. It would be possible for Linuxbrew to work on 32-bit x86 platforms with some effort. Pull requests would be welcome if someone were to volunteer to maintain the 32-bit x86 support.

Bottles
-------

Bottles are Linuxbrew's precompiled binary packages. Linuxbrew bottles work on any Linux system. They do however require `glibc` 2.19 or better. On systems with an older version of `glibc`, Linuxbrew will install `glibc` the first time that you install a bottled formula. If you prefer to use the `glibc` provided by your system and build all formulas from source, add to your `.bashrc` or `.zshrc`:

`export HOMEBREW_BUILD_FROM_SOURCE=1`

Installation
------------

Paste at a Terminal prompt:

```sh
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Linuxbrew/install/master/install)"
```

Or if you prefer:

```sh
git clone https://github.com/Linuxbrew/brew.git ~/.linuxbrew
```

Add to your `.bashrc` or `.zshrc`:

```sh
export PATH="$HOME/.linuxbrew/bin:$PATH"
export MANPATH="$HOME/.linuxbrew/share/man:$MANPATH"
export INFOPATH="$HOME/.linuxbrew/share/info:$INFOPATH"
```

You're done! Try installing a package:

```sh
brew install hello
```

If you're using an older distribution of Linux, installing your first package will also install a recent version of `gcc`.

## Update Bug
If Homebrew was updated on Aug 10-11th 2016 and `brew update` always says `Already up-to-date.` you need to run:
```bash
cd "$(brew --repo)" && git fetch && git reset --hard origin/master && brew update
```

## What Packages Are Available?
1. Type `brew search` for a list.
2. Or visit [braumeister.org](http://braumeister.org) to browse packages online.
3. Or use `brew search --desc <keyword>` to browse packages from the command line.

## More Documentation
`brew help`, `man brew` or check [our documentation](https://github.com/Linuxbrew/brew/tree/master/docs#readme).

## Troubleshooting
First, please run `brew update` and `brew doctor`.

Second, read the [Troubleshooting Checklist](https://github.com/Linuxbrew/brew/blob/master/docs/Troubleshooting.md#troubleshooting).

**If you don't read these it will take us far longer to help you with your problem.**

## Something broke!

Many of the Homebrew formulae work on either Mac or Linux without changes, but some formulae will need to be adapted for Linux. If a formula doesn't work, [open an issue on GitHub](https://github.com/Linuxbrew/linuxbrew/issues) or, even better, submit a pull request.

## Contributing
We'd love you to contribute to Linuxbrew or its upstream project, Homebrew. First, please read our [Contribution Guide](https://github.com/Linuxbrew/brew/blob/master/CONTRIBUTING.md) and [Code of Conduct](https://github.com/Linuxbrew/brew/blob/master/CODEOFCONDUCT.md#code-of-conduct). Please see our [guidelines](https://github.com/Linuxbrew/brew/blob/master/CONTRIBUTING.md#contributing-to-linuxbrew) on whether to send pull requests to Linuxbrew or Homebrew.

We explicitly welcome contributions from people who have never contributed to open-source before: we were all beginners once! We can help build on a partially working pull request with the aim of getting it merged. We are also actively seeking to diversify our contributors and especially welcome contributions from women from all backgrounds and people of colour.

A good starting point for contributing is running `brew audit` (or `brew audit --strict`) with some of the packages you use (e.g. `brew audit wget` if you use `wget`) and then read through the warnings, try to fix them until `brew audit` shows no results and [submit a pull request](https://github.com/Homebrew/brew/blob/master/docs/How-To-Open-a-Homebrew-Pull-Request-(and-get-it-merged).md). If no formulae you use have warnings you can run `brew audit` without arguments to have it run on all packages and pick one. Good luck!

## Security
Please report security issues to security@brew.sh.

This is our PGP key which is valid until May 24, 2017.
* Key ID: `0xE33A3D3CCE59E297`
* Fingerprint: `C657 8F76 2E23 441E C879  EC5C E33A 3D3C CE59 E297`
* Full key: https://keybase.io/homebrew/key.asc

## Who Are You?
Linuxbrew is maintained by [Shaun Jackman](http://sjackman.ca), [Bob W. Hogg](https://github.com/rwhogg), [Piotr Gaczkowski](https://github.com/DoomHammer) and [Maxim Belkin](https://github.com/maxim-belkin).

Homebrew's lead maintainer is [Mike McQuaid](https://github.com/mikemcquaid).

Homebrew's current maintainers are [Misty De Meo](https://github.com/mistydemeo), [Andrew Janke](https://github.com/apjanke), [Xu Cheng](https://github.com/xu-cheng), [Tomasz Pajor](https://github.com/nijikon), [Josh Hagins](https://github.com/jawshooah), [Baptiste Fontaine](https://github.com/bfontaine), [Markus Reiter](https://github.com/reitermarkus), [ilovezfs](https://github.com/ilovezfs), [Martin Afanasjew](https://github.com/UniqMartin), [Tom Schoonjans](https://github.com/tschoonj), [Uladzislau Shablinski](https://github.com/vladshablinsky), [Tim Smith](https://github.com/tdsmith) and [Alex Dunn](https://github.com/dunn).

Former maintainers with significant contributions include [Dominyk Tiller](https://github.com/DomT4), [Brett Koonce](https://github.com/asparagui), [Jack Nagel](https://github.com/jacknagel), [Adam Vandenberg](https://github.com/adamv) and Homebrew's creator: [Max Howell](https://github.com/mxcl).

## License
Code is under the [BSD 2-clause "Simplified" License](https://github.com/Homebrew/brew/tree/master/LICENSE.txt).
Documentation is under the [Creative Commons Attribution license](https://creativecommons.org/licenses/by/4.0/).

## Donations
Homebrew is a non-profit project run entirely by unpaid volunteers. We need your funds to pay for software, hardware and hosting around continuous integration and future improvements to the project. Every donation will be spent on making Homebrew better for our users.

Please consider a regular donation to Homebrew, the upstream project of Linuxbrew, through Patreon:

[![Donate with Patreon](https://img.shields.io/badge/patreon-donate-green.svg)](https://www.patreon.com/homebrew)

## Sponsors
Our CI infrastructure was paid for by [our Kickstarter supporters](https://github.com/Homebrew/brew/blob/master/docs/Kickstarter-Supporters.md).

Our CI infrastructure is hosted by [The Positive Internet Company](http://www.positive-internet.com).

Our bottles (binary packages) are hosted by Bintray.

[![Downloads by Bintray](https://bintray.com/docs/images/downloads_by_bintray_96.png)](https://bintray.com/homebrew)

Secure password storage and syncing provided by [1Password for Teams](https://1password.com/teams/) by AgileBits

[![AgileBits](https://da36klfizjv29.cloudfront.net/assets/branding/agilebits-fcca96e9b8e815c5c48c6b3e98156cb5.png)](https://agilebits.com)

Homebrew is a member of the [Software Freedom Conservancy](https://sfconservancy.org)

[![Software Freedom Conservancy](https://sfconservancy.org/img/conservancy_64x64.png)](https://sfconservancy.org)
