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
sudo apt-get install build-essential curl file git python-setuptools ruby
```

### Fedora, CentOS or Red Hat

```sh
sudo yum groupinstall 'Development Tools' && sudo yum install curl file git irb python-setuptools ruby
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

Many of the Homebrew formulae work on either Mac or Linux without changes, but some formulae will need to be adapted for Linux. If a formula doesn't work, [open an issue on GitHub](https://github.com/Linuxbrew/homebrew-core/issues) or, even better, submit a pull request.

## Contributing
We'd love you to contribute to Linuxbrew or its upstream project, Homebrew. First, please read our [Contribution Guide](https://github.com/Linuxbrew/brew/blob/master/CONTRIBUTING.md) and [Code of Conduct](https://github.com/Linuxbrew/brew/blob/master/CODEOFCONDUCT.md#code-of-conduct). Please see our [guidelines](https://github.com/Linuxbrew/brew/blob/master/CONTRIBUTING.md#contributing-to-linuxbrew) on whether to send pull requests to Linuxbrew or Homebrew.

We explicitly welcome contributions from people who have never contributed to open-source before: we were all beginners once! We can help build on a partially working pull request with the aim of getting it merged. We are also actively seeking to diversify our contributors and especially welcome contributions from women from all backgrounds and people of colour.

A good starting point for contributing is running `brew audit --strict`with some of the packages you use (e.g. `brew audit --strict wget` if you use `wget`) and then read through the warnings, try to fix them until `brew audit --strict` shows no results and [submit a pull request](http://docs.brew.sh/How-To-Open-a-Homebrew-Pull-Request.html). If no formulae you use have warnings you can run `brew audit --strict` without arguments to have it run on all packages and pick one. Good luck!

## Security
Please report security issues to security@brew.sh.

This is our PGP key which is valid until May 24, 2017.
* Key ID: `0xE33A3D3CCE59E297`
* Fingerprint: `C657 8F76 2E23 441E C879  EC5C E33A 3D3C CE59 E297`
* Full key: https://keybase.io/homebrew/key.asc

## Who Are You?
Linuxbrew is maintained by [Shaun Jackman](http://sjackman.ca), [Piotr Gaczkowski](https://github.com/DoomHammer), [Maxim Belkin](https://github.com/maxim-belkin), and [Jonathan Chang](https://github.com/jonchang).

[Bob W. Hogg](https://github.com/rwhogg) is also a Linuxbrew maintainer, but is currently on leave and will return later in the year.

Homebrew's lead maintainer is [Mike McQuaid](https://github.com/mikemcquaid).

Homebrew's current maintainers are [Alyssa Ross](https://github.com/alyssais), [Andrew Janke](https://github.com/apjanke), [Baptiste Fontaine](https://github.com/bfontaine), [Alex Dunn](https://github.com/dunn), [FX Coudert](https://github.com/fxcoudert), [ilovezfs](https://github.com/ilovezfs), [Josh Hagins](https://github.com/jawshooah), [JCount](https://github.com/jcount), [Misty De Meo](https://github.com/mistydemeo), [neutric](https://github.com/neutric), [Tomasz Pajor](https://github.com/nijikon), [Markus Reiter](https://github.com/reitermarkus), [Tim Smith](https://github.com/tdsmith), [Tom Schoonjans](https://github.com/tschoonj), [Uladzislau Shablinski](https://github.com/vladshablinsky) and [William Woodruff](https://github.com/woodruffw).

Former maintainers with significant contributions include [Xu Cheng](https://github.com/xu-cheng), [Martin Afanasjew](https://github.com/UniqMartin), [Dominyk Tiller](https://github.com/DomT4), [Brett Koonce](https://github.com/asparagui), [Jack Nagel](https://github.com/jacknagel), [Adam Vandenberg](https://github.com/adamv) and Homebrew's creator: [Max Howell](https://github.com/mxcl).

## Community
- [discourse.brew.sh (forum)](https://discourse.brew.sh)
- [freenode.net\#machomebrew (IRC)](irc://irc.freenode.net/#machomebrew)
- [@MacHomebrew (Twitter)](https://twitter.com/MacHomebrew)

## License
Code is under the [BSD 2-clause "Simplified" License](https://github.com/Homebrew/brew/tree/master/LICENSE.txt).
Documentation is under the [Creative Commons Attribution license](https://creativecommons.org/licenses/by/4.0/).

## Donations
Homebrew is a non-profit project run entirely by unpaid volunteers. We need your funds to pay for software, hardware and hosting around continuous integration and future improvements to the project. Every donation will be spent on making Homebrew better for our users.

Please consider a regular donation to Homebrew, the upstream project of Linuxbrew, through Patreon:

[![Donate with Patreon](https://img.shields.io/badge/patreon-donate-green.svg)](https://www.patreon.com/homebrew)

## Sponsors
Our Xserve ESXi boxes for CI are hosted by [MacStadium](https://www.macstadium.com).

[![Powered by MacStadium](https://cloud.githubusercontent.com/assets/125011/22776032/097557ac-eea6-11e6-8ba8-eff22dfd58f1.png)](https://www.macstadium.com)

Our Mac Minis for CI were paid for by [our Kickstarter supporters](http://docs.brew.sh/Kickstarter-Supporters.html).

Our Mac Minis for CI are hosted by [The Positive Internet Company](http://www.positive-internet.com).

Our bottles (binary packages) are hosted by [Bintray](https://bintray.com/homebrew).

[![Downloads by Bintray](https://bintray.com/docs/images/downloads_by_bintray_96.png)](https://bintray.com/homebrew)

[Our website](https://brew.sh) is hosted by [Netlify](https://www.netlify.com).

[![Deploys by Netlify](https://www.netlify.com/img/global/badges/netlify-color-accent.svg)](https://www.netlify.com)

Secure password storage and syncing provided by [1Password for Teams](https://1password.com/teams/) by [AgileBits](https://agilebits.com)

[![AgileBits](https://da36klfizjv29.cloudfront.net/assets/branding/agilebits-fcca96e9b8e815c5c48c6b3e98156cb5.png)](https://agilebits.com)

Homebrew is a member of the [Software Freedom Conservancy](https://sfconservancy.org)

[![Software Freedom Conservancy](https://sfconservancy.org/img/conservancy_64x64.png)](https://sfconservancy.org)
