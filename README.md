# Cadfaelbrew

Cadfaelbrew is a fork of [Linuxbrew](http://linuxbrew.sh), the Mac OS/Linux package manager, for the SuperNEMO-DBD
experiment.

It can be installed in your home directory and does not require root access. The same package manager can be used on both your Linux server and your Mac laptop. Installing a modern version of *glibc* and *gcc* in your home directory on an old distribution of Linux takes five minutes.

Features, usage and installation instructions are summarised below.
Features, usage and installation instructions are summarised on the below. Terminology (e.g. the difference between a Cellar, Tap, Cask and so forth) is [explained here](docs/Formula-Cookbook.md#homebrew-terminology).

Cadfaelbrew follows upstream linuxbrew/brew with some lag depending on production requirements.
Merges typically happen on 1 month cycles. To receive updates of major changes to Linuxbrew subscribe
to the [Linuxbrew Updates](https://github.com/linuxbrew/brew/issues/1) issue on GitHub.

If you require an update that's in linuxbrew and not yet merged into Cadfaelbrew, please raise an issue.

Features
--------
+ Can install software to a home directory and so does not require sudo
+ Install software not packaged by the native distribution
+ Install up-to-date versions of software when the native distribution is old
+ Use the same package manager to manage both your Mac and Linux machines


Install Cadfaelbrew (tl;dr)
--------------------------
```sh
$ git clone https://github.com/SuperNEMO-DBD/brew.git ~/CadfaelBrew
```

Add to your `.bashrc` or `.zshrc`:

```sh
export PATH="$HOME/CadfaelBrew/bin:$PATH"
export MANPATH="$HOME/CadfaelBrew/share/man:$MANPATH"
export INFOPATH="$HOME/CadfaelBrew/share/info:$INFOPATH"
```

```sh
$ brew cadfael-bootstrap
$ brew install falaise
```
The second command installs the main SuperNEMO software package, Falaise, which is provided in
a [dedicated `tap` for SuperNEMO](https://github.com/SuperNEMO-DBD/homebrew-cadfael).

You're done! Unless you saw errors, in which case review [Dependencies](#dependencies) and [Installation](#installation)
below for more details. If these do not solve the issue, please read the [Troubleshooting Checklist](https://github.com/SuperNEMO-DBD/brew/blob/master/share/doc/homebrew/Troubleshooting.md#troubleshooting) and submit an Issue following the instructions there if required.

Dependencies
------------
+ **Mac OS X**
  + **OS X** 10.9 or newer
  + **Xcode** 6 or newer
+ **Linux**:
  * **Ruby** 1.8.6 or newer
  + **GCC** 4.2 or newer
  * **Git** 1.7.12.4 or newer
  + **Linux** 2.6.16 or newer
  + **64-bit x86** or **32-bit ARM** platform

A dedicated brew command `cadfael-bootstrap` is provided to check system dependencies and will
check everything for you and report any missing items with some instructions on how to install them.
The actual packages required and checked for on Linux systems are listed below including the command(s)
needed to install them.

### Ubuntu

```sh
sudo apt-get install \
  build-essential \
  curl \
  git \
  python-setuptools \
  ruby2.0 \
  m4 \
  libbz2-dev \
  libcurl4-openssl-dev \
  libexpat-dev \
  libncurses-dev \
  texinfo \
  zlib1g-dev \
  libx11-dev \
  libxpm-dev \
  libxft-dev \
  libxext-dev \
  libpng12-dev \
  libjpeg-dev
```

### CentOS or Red Hat

```sh
sudo yum groupinstall 'Development Tools'
sudo yum install \
  curl \
  file \
  git \
  irb \
  python-setuptools \
  ruby \
  redhat-lsb-core
```

On RedHat/CentOS/Scientific, you will also require the `HEP_OSlibs` meta package from CERN.
Installation instructions for this are dependent on whether you are running version 6 or 7 of
these distros:

- [Instructions for CentOS 6](https://twiki.cern.ch/twiki/bin/view/LCG/SL6DependencyRPM)
- [Instructions for CentOS 7](https://twiki.cern.ch/twiki/bin/view/LCG/CentOS7DependencyRPM)

### 32-bit x86 platforms

Cadfaelbrew does not currently support 32-bit x86 platforms.

Bottles
-------

Bottles are Homebrew/Linuxbrew's precompiled binary packages. SuperNEMO-DBD's fork of brew only supports these
on Mac OS at present, use of Linux bottles is possible but is currently being tested. On Linux, all packages are
forced to build from source.


Installation
------------
```sh
git clone https://github.com/SuperNEMO-DBD/brew.git ~/CadfaelBrew
```

Add to your `.bashrc` or `.zshrc`:

```sh
export PATH="$HOME/CadfaelBrew/bin:$PATH"
export MANPATH="$HOME/CadfaelBrew/share/man:$MANPATH"
export INFOPATH="$HOME/CadfaelBrew/share/info:$INFOPATH"
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
`brew help`, `man brew` or check [our documentation](https://github.com/SuperNEMO-DBD/brew/tree/master/docs#readme).

## Troubleshooting
First, please run `brew update` and `brew doctor`.

Second, read the [Troubleshooting Checklist](https://github.com/SuperNEMO-DBD/brew/blob/master/docs/Troubleshooting.md#troubleshooting).

**If you don't read these it will take us far longer to help you with your problem.**

## Something broke!

Many of the Homebrew formulae work on either Mac or Linux without changes, but some formulae will need to be adapted for Linux. If a formula doesn't work, [open an issue on GitHub](https://github.com/SuperNEMO-DBD/brew/issues) or, even better, submit a pull request.

## Contributing
We'd love you to contribute to Linuxbrew or its upstream project, Homebrew. First, please read our [Contribution Guide](https://github.com/SuperNEMO-DBD/brew/blob/master/CONTRIBUTING.md) and [Code of Conduct](https://github.com/SuperNEMO-DBD/brew/blob/master/CODEOFCONDUCT.md#code-of-conduct). Please see our [guidelines](https://github.com/SuperNEMO-DBD/brew/blob/master/CONTRIBUTING.md#contributing-to-linuxbrew) on whether to send pull requests to Linuxbrew or Homebrew.

We explicitly welcome contributions from people who have never contributed to open-source before: we were all beginners once! We can help build on a partially working pull request with the aim of getting it merged. We are also actively seeking to diversify our contributors and especially welcome contributions from women from all backgrounds and people of colour.

A good starting point for contributing is running `brew audit --strict`with some of the packages you use (e.g. `brew audit --strict wget` if you use `wget`) and then read through the warnings, try to fix them until `brew audit --strict` shows no results and [submit a pull request](http://docs.brew.sh/How-To-Open-a-Homebrew-Pull-Request.html). If no formulae you use have warnings you can run `brew audit --strict` without arguments to have it run on all packages and pick one. Good luck!

## Security
Please report security issues directly to the main homebrew security team: security@brew.sh.

This is our PGP key which is valid until May 24, 2017.
* Key ID: `0xE33A3D3CCE59E297`
* Fingerprint: `C657 8F76 2E23 441E C879  EC5C E33A 3D3C CE59 E297`
* Full key: https://keybase.io/homebrew/key.asc

## Who Are You?
SuperNEMO-DBD's fork of brew is maintained by [Ben Morgan](https://github.com/drbenmorgan).

Linuxbrew is maintained by [Shaun Jackman](http://sjackman.ca), [Bob W. Hogg](https://github.com/rwhogg), [Piotr Gaczkowski](https://github.com/DoomHammer) and [Maxim Belkin](https://github.com/maxim-belkin).

Homebrew's lead maintainer is [Mike McQuaid](https://github.com/mikemcquaid).

Homebrew's current maintainers are [Alyssa Ross](https://github.com/alyssais), [Andrew Janke](https://github.com/apjanke), [Baptiste Fontaine](https://github.com/bfontaine), [Alex Dunn](https://github.com/dunn), [FX Coudert](https://github.com/fxcoudert), [ilovezfs](https://github.com/ilovezfs), [Josh Hagins](https://github.com/jawshooah), [JCount](https://github.com/jcount), [Misty De Meo](https://github.com/mistydemeo), [neutric](https://github.com/neutric), [Tomasz Pajor](https://github.com/nijikon), [Markus Reiter](https://github.com/reitermarkus), [Tim Smith](https://github.com/tdsmith), [Tom Schoonjans](https://github.com/tschoonj), [Uladzislau Shablinski](https://github.com/vladshablinsky) and [William Woodruff](https://github.com/woodruffw).

Former maintainers with significant contributions include [Xu Cheng](https://github.com/xu-cheng), [Martin Afanasjew](https://github.com/UniqMartin), [Dominyk Tiller](https://github.com/DomT4), [Brett Koonce](https://github.com/asparagui), [Jack Nagel](https://github.com/jacknagel), [Adam Vandenberg](https://github.com/adamv) and Homebrew's creator: [Max Howell](https://github.com/mxcl).

## Community
- [discourse.brew.sh (forum)](https://discourse.brew.sh)
- [freenode.net\#machomebrew (IRC)](irc://irc.freenode.net/#machomebrew)
- [@MacHomebrew (Twitter)](https://twitter.com/MacHomebrew)

## License
Code is under the [BSD 2-clause "Simplified" License](https://github.com/SuperNEMO-DBD/brew/tree/master/LICENSE.txt).
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
