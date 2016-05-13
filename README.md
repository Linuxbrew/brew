# Cadfaelbrew

Cadfaelbrew is a fork of [Linuxbrew](http://linuxbrew.sh), the Mac OS/Linux package manager, for the SuperNEMO-DBD 
experiment.

It can be installed in your home directory and does not require root access. The same package manager can be used on both your Linux server and your Mac laptop. Installing a modern version of *glibc* and *gcc* in your home directory on an old distribution of Linux takes five minutes.

Features, usage and installation instructions are summarised below.

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
  git \
  irb \
  python-setuptools \
  ruby \
  redhat-lsb-core \
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

You're done!

```sh
brew install $WHATEVER_YOU_WANT
```

## What Packages Are Available?
1. Type `brew search` for a list.
2. Or visit [braumeister.org](http://braumeister.org) to browse packages online.
3. Or use `brew search --desc` to browse packages from the command line.

## More Documentation
`brew help`, `man brew` or check [our documentation](https://github.com/SuperNEMO-DBD/brew/tree/master/share/doc/homebrew#readme).

## Troubleshooting
First, please run `brew update` and `brew doctor`.

Second, read the [Troubleshooting Checklist](https://github.com/SuperNEMO-DBD/brew/blob/master/share/doc/homebrew/Troubleshooting.md#troubleshooting).

**If you don't read these it will take us far longer to help you with your problem.**

## Something broke!

Many of the Homebrew formulae work on either Mac or Linux without changes, but some formulae will need to be adapted for Linux. If a formula doesn't work, [open an issue on GitHub](https://github.com/SuperNEMO-DBD/brew/issues) or, even better, submit a pull request.

## Security
Please report security issues directly to the main homebrew security team: security@brew.sh.

This is our PGP key which is valid until June 17, 2016.
* Key ID: `0xE33A3D3CCE59E297`
* Fingerprint: `C657 8F76 2E23 441E C879  EC5C E33A 3D3C CE59 E297`
* Full key: https://keybase.io/homebrew/key.asc

## Who Are You?
SuperNEMO-DBD's for of brew is maintained by [Ben Morgan](https://github.com/drbenmorgan).

Linuxbrew is maintained by [Shaun Jackman](https://github.com/sjackman).

Homebrew's current maintainers are [Misty De Meo](https://github.com/mistydemeo), [Andrew Janke](https://github.com/apjanke), [Xu Cheng](https://github.com/xu-cheng), [Mike McQuaid](https://github.com/mikemcquaid), [Baptiste Fontaine](https://github.com/bfontaine), [Brett Koonce](https://github.com/asparagui), [Martin Afanasjew](https://github.com/UniqMartin), [Dominyk Tiller](https://github.com/DomT4), [Tim Smith](https://github.com/tdsmith) and [Alex Dunn](https://github.com/dunn).

Former maintainers with significant contributions include [Jack Nagel](https://github.com/jacknagel), [Adam Vandenberg](https://github.com/adamv) and Homebrew's creator: [Max Howell](https://github.com/mxcl).

## License
Code is under the [BSD 2 Clause (NetBSD) license](https://github.com/Homebrew/homebrew/tree/master/LICENSE.txt).
Documentation is under the [Creative Commons Attribution license](https://creativecommons.org/licenses/by/4.0/).

## Donations
Homebrew is a non-profit project run entirely by unpaid volunteers. We need your funds to pay for software, hardware and hosting around continuous integration and future improvements to the project. Every donation will be spent on making Homebrew better for our users.

Homebrew, the upstream project of Linuxbrew, is a member of the [Software Freedom Conservancy](http://sfconservancy.org) which provides Homebrew with an ability to receive tax-deductible, Homebrew earmarked donations (and [many other services](http://sfconservancy.org/members/services/)). Software Freedom Conservancy, Inc. is a 501(c)(3) organization incorporated in New York, and donations made to it are fully tax-deductible to the extent permitted by law.

- [Donate with PayPal](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=V6ZE57MJRYC8L)
- Donate by USA $ check from a USA bank:
  - Make check payable to "Software Freedom Conservancy, Inc." and place "Directed donation: Homebrew" in the memo field.  Checks should then be mailed to:
    - Software Freedom Conservancy, Inc.  
      137 Montague ST  STE 380  
      BROOKLYN, NY 11201             USA  
- Donate by wire transfer: contact accounting@sfconservancy.org for wire transfer details.
- Donate with Flattr or PayPal Giving Fund: coming soon.

## Sponsors
Our CI infrastructure was paid for by [our Kickstarter supporters](https://github.com/Homebrew/homebrew/blob/master/share/doc/homebrew/Kickstarter-Supporters.md).

Our CI infrastructure is hosted by [The Positive Internet Company](http://www.positive-internet.com).

Our bottles (binary packages) are hosted by Bintray.

[![Downloads by Bintray](https://bintray.com/docs/images/downloads_by_bintray_96.png)](https://bintray.com/homebrew)

Homebrew is a member of the [Software Freedom Conservancy](https://sfconservancy.org)

[![Software Freedom Conservancy](https://sfconservancy.org/img/conservancy_64x64.png)](https://sfconservancy.org)
