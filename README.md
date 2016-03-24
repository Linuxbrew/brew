# Linuxbrew

[Linuxbrew](http://linuxbrew.sh) is a fork of [Homebrew](http://brew.sh), the Mac OS package manager, for Linux.

It can be installed in your home directory and does not require root access. The same package manager can be used on both your Linux server and your Mac laptop. Installing a modern version of *glibc* and *gcc* in your home directory on an old distribution of Linux takes five minutes.

Features, usage and installation instructions are [summarised on the homepage](http://linuxbrew.sh).

To receive updates of major changes to Linuxbrew subscribe to the [Linuxbrew Updates](https://github.com/Linuxbrew/linuxbrew/issues/864) issue on GitHub.

Install Linuxbrew (tl;dr)
-------------------------

Paste at a Terminal prompt:

``` sh
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Linuxbrew/linuxbrew/go/install)"
```

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
+ **64-bit x86** or **32-bit ARM** platform

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

``` sh
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Linuxbrew/linuxbrew/go/install)"
```

Or if you prefer:

```sh
git clone https://github.com/Linuxbrew/linuxbrew.git ~/.linuxbrew
```

Add to your `.bashrc` or `.zshrc`:

```sh
export PATH="$HOME/.linuxbrew/bin:$PATH"
export MANPATH="$HOME/.linuxbrew/share/man:$MANPATH"
export INFOPATH="$HOME/.linuxbrew/share/info:$INFOPATH"
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
`brew help`, `man brew` or check [our documentation](https://github.com/Linuxbrew/linuxbrew/tree/master/share/doc/homebrew#readme).

## Troubleshooting
First, please run `brew update` and `brew doctor`.

Second, read the [Troubleshooting Checklist](https://github.com/Linuxbrew/linuxbrew/blob/master/share/doc/homebrew/Troubleshooting.md#troubleshooting).

**If you don't read these it will take us far longer to help you with your problem.**

## Something broke!

Many of the Homebrew formulae work on either Mac or Linux without changes, but some formulae will need to be adapted for Linux. If a formula doesn't work, [open an issue on GitHub](https://github.com/Linuxbrew/linuxbrew/issues) or, even better, submit a pull request.

## Security
Please report security issues to security@brew.sh.

This is our PGP key which is valid until June 17, 2016.
* Key ID: `0xE33A3D3CCE59E297`
* Fingerprint: `C657 8F76 2E23 441E C879  EC5C E33A 3D3C CE59 E297`
* Full key: https://keybase.io/homebrew/key.asc

## Who Are You?
Linuxbrew is maintained by [Shaun Jackman](http://sjackman.ca).

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
