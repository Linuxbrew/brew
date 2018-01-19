# Homebrew
[![GitHub release](https://img.shields.io/github/release/Homebrew/brew.svg)](https://github.com/Homebrew/brew/releases)

Features, usage and installation instructions are [summarised on the homepage](https://brew.sh). Terminology (e.g. the difference between a Cellar, Tap, Cask and so forth) is [explained here](docs/Formula-Cookbook.md#homebrew-terminology).

## What Packages Are Available?
1. Type `brew search` for a list.
2. Or visit [formulae.brew.sh](http://formulae.brew.sh) to browse packages online.
3. Or use `brew search --desc <keyword>` to browse packages from the command line.

## More Documentation
`brew help`, `man brew` or check [our documentation](https://docs.brew.sh/).

## Troubleshooting
First, please run `brew update` and `brew doctor`.

Second, read the [Troubleshooting Checklist](https://docs.brew.sh/Troubleshooting.html).

**If you don't read these it will take us far longer to help you with your problem.**

## Contributing
[![Travis](https://img.shields.io/travis/Homebrew/brew.svg)](https://travis-ci.org/Homebrew/brew)
[![Codecov](https://img.shields.io/codecov/c/github/Homebrew/brew.svg)](https://codecov.io/gh/Homebrew/brew)

We'd love you to contribute to Homebrew. First, please read our [Contribution Guide](https://github.com/Homebrew/brew/blob/master/CONTRIBUTING.md) and [Code of Conduct](https://github.com/Homebrew/brew/blob/master/CODE_OF_CONDUCT.md#code-of-conduct).

We explicitly welcome contributions from people who have never contributed to open-source before: we were all beginners once! We can help build on a partially working pull request with the aim of getting it merged. We are also actively seeking to diversify our contributors and especially welcome contributions from women from all backgrounds and people of colour.

A good starting point for contributing is running `brew audit --strict` with some of the packages you use (e.g. `brew audit --strict wget` if you use `wget`) and then read through the warnings, try to fix them until `brew audit --strict` shows no results and [submit a pull request](https://docs.brew.sh/How-To-Open-a-Homebrew-Pull-Request.html). If no formulae you use have warnings you can run `brew audit --strict` without arguments to have it run on all packages and pick one.

Alternatively, for something more substantial, check out one of the issues labeled `help wanted` in [Homebrew/brew](https://github.com/homebrew/brew/issues?q=is%3Aopen+is%3Aissue+label%3A%22help+wanted%22) or [Homebrew/homebrew-core](https://github.com/homebrew/homebrew-core/issues?q=is%3Aopen+is%3Aissue+label%3A%22help+wanted%22).

Good luck!

## Security
Please report security issues to our [HackerOne](https://hackerone.com/homebrew/).

## Who Are You?
Homebrew's lead maintainer is [Mike McQuaid](https://github.com/mikemcquaid).

Homebrew/homebrew-core's lead maintainer is [ilovezfs](https://github.com/ilovezfs).

Homebrew/brew's other current maintainers are [ilovezfs](https://github.com/ilovezfs), [Alyssa Ross](https://github.com/alyssais), [JCount](https://github.com/jcount), [Misty De Meo](https://github.com/mistydemeo), [Gautham Goli](https://github.com/GauthamGoli), [Markus Reiter](https://github.com/reitermarkus) and [William Woodruff](https://github.com/woodruffw).

Homebrew/homebrew-core's other current maintainers are [FX Coudert](https://github.com/fxcoudert), [JCount](https://github.com/jcount), [Misty De Meo](https://github.com/mistydemeo) and [Tom Schoonjans](https://github.com/tschoonj).

Former maintainers with significant contributions include [Tim Smith](https://github.com/tdsmith), [Baptiste Fontaine](https://github.com/bfontaine), [Xu Cheng](https://github.com/xu-cheng), [Martin Afanasjew](https://github.com/UniqMartin), [Dominyk Tiller](https://github.com/DomT4), [Brett Koonce](https://github.com/asparagui), [Charlie Sharpsteen](https://github.com/Sharpie), [Jack Nagel](https://github.com/jacknagel), [Adam Vandenberg](https://github.com/adamv), [Andrew Janke](https://github.com/apjanke), [Alex Dunn](https://github.com/dunn), [neutric](https://github.com/neutric), [Tomasz Pajor](https://github.com/nijikon), [Uladzislau Shablinski](https://github.com/vladshablinsky) and Homebrew's creator: [Max Howell](https://github.com/mxcl).

## Community
- [discourse.brew.sh (forum)](https://discourse.brew.sh)
- [freenode.net\#machomebrew (IRC)](irc://irc.freenode.net/#machomebrew)
- [@MacHomebrew (Twitter)](https://twitter.com/MacHomebrew)

## License
Code is under the [BSD 2-clause "Simplified" License](https://github.com/Homebrew/brew/tree/master/LICENSE.txt).
Documentation is under the [Creative Commons Attribution license](https://creativecommons.org/licenses/by/4.0/).

## Donations
Homebrew is a non-profit project run entirely by unpaid volunteers. We need your funds to pay for software, hardware and hosting around continuous integration and future improvements to the project. Every donation will be spent on making Homebrew better for our users.

Please consider a regular donation through Patreon:

[![Donate with Patreon](https://img.shields.io/badge/patreon-donate-green.svg)](https://www.patreon.com/homebrew)

Alternatively, if you'd rather make a one-off payment:

- [Donate with PayPal](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=V6ZE57MJRYC8L)
- Donate by USA $ check from a USA bank:
  - Make check payable to "Software Freedom Conservancy, Inc." and place "Directed donation: Homebrew" in the memo field.  Checks should then be mailed to:
    - Software Freedom Conservancy, Inc.
      137 Montague ST  STE 380
      BROOKLYN, NY 11201             USA
- Donate by wire transfer: contact accounting@sfconservancy.org for wire transfer details.

Homebrew is a member of the [Software Freedom Conservancy](https://sfconservancy.org) which provides us with an ability to receive tax-deductible, Homebrew earmarked donations (and [many other services](https://sfconservancy.org/members/services/)). Software Freedom Conservancy, Inc. is a 501(c)(3) organization incorporated in New York, and donations made to it are fully tax-deductible to the extent permitted by law.

## Sponsors
Our Xserve ESXi boxes for CI are hosted by [MacStadium](https://www.macstadium.com).

[![Powered by MacStadium](https://cloud.githubusercontent.com/assets/125011/22776032/097557ac-eea6-11e6-8ba8-eff22dfd58f1.png)](https://www.macstadium.com)

Our Jenkins CI installation is hosted by [DigitalOcean](https://m.do.co/c/7e39c35d5581).

![DigitalOcean](https://cloud.githubusercontent.com/assets/125011/26827038/4b7b5ade-4ab3-11e7-811b-fed3ab0e934d.png)

Our physical hardware is hosted by [Commsworld](https://www.commsworld.com).

![Commsworld powered by Fluency](https://user-images.githubusercontent.com/125011/30822845-1716bc2c-a222-11e7-843e-ea7c7b6a1503.png)

Our bottles (binary packages) are hosted by [Bintray](https://bintray.com/homebrew).

[![Downloads by Bintray](https://bintray.com/docs/images/downloads_by_bintray_96.png)](https://bintray.com/homebrew)

[Our website](https://brew.sh) is hosted by [Netlify](https://www.netlify.com).

[![Deploys by Netlify](https://www.netlify.com/img/global/badges/netlify-color-accent.svg)](https://www.netlify.com)

Secure password storage and syncing provided by [1Password for Teams](https://1password.com/teams/) by [AgileBits](https://agilebits.com).

[![AgileBits](https://da36klfizjv29.cloudfront.net/assets/branding/agilebits-fcca96e9b8e815c5c48c6b3e98156cb5.png)](https://agilebits.com)

Homebrew is a member of the [Software Freedom Conservancy](https://sfconservancy.org).

[![Software Freedom Conservancy](https://sfconservancy.org/img/conservancy_64x64.png)](https://sfconservancy.org)
