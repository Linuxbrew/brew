# Homebrew
[![GitHub release](https://img.shields.io/github/release/Homebrew/brew.svg)](https://github.com/Homebrew/brew/releases)

Features, usage and installation instructions are [summarised on the homepage](https://brew.sh). Terminology (e.g. the difference between a Cellar, Tap, Cask and so forth) is [explained here](docs/Formula-Cookbook.md#homebrew-terminology).

## What Packages Are Available?
1. Type `brew search` for a list.
2. Or visit [braumeister.org](http://braumeister.org) to browse packages online.
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

We'd love you to contribute to Homebrew. First, please read our [Contribution Guide](https://github.com/Homebrew/brew/blob/master/CONTRIBUTING.md) and [Code of Conduct](https://github.com/Homebrew/brew/blob/master/CODEOFCONDUCT.md#code-of-conduct).

We explicitly welcome contributions from people who have never contributed to open-source before: we were all beginners once! We can help build on a partially working pull request with the aim of getting it merged. We are also actively seeking to diversify our contributors and especially welcome contributions from women from all backgrounds and people of colour.

A good starting point for contributing is running `brew audit --strict` with some of the packages you use (e.g. `brew audit --strict wget` if you use `wget`) and then read through the warnings, try to fix them until `brew audit --strict` shows no results and [submit a pull request](https://docs.brew.sh/How-To-Open-a-Homebrew-Pull-Request.html). If no formulae you use have warnings you can run `brew audit --strict` without arguments to have it run on all packages and pick one. Good luck!

## Security
Please report security issues to our [HackerOne](https://hackerone.com/homebrew/).

## Who Are You?
Homebrew's lead maintainer is [Mike McQuaid](https://github.com/mikemcquaid).

Homebrew/homebrew-core's lead maintainer is [ilovezfs](https://github.com/ilovezfs).

Homebrew's other current maintainers are [Alyssa Ross](https://github.com/alyssais), [Andrew Janke](https://github.com/apjanke), [Alex Dunn](https://github.com/dunn), [FX Coudert](https://github.com/fxcoudert), [Josh Hagins](https://github.com/jawshooah), [JCount](https://github.com/jcount), [Misty De Meo](https://github.com/mistydemeo), [neutric](https://github.com/neutric), [Tomasz Pajor](https://github.com/nijikon), [Markus Reiter](https://github.com/reitermarkus), [Tim Smith](https://github.com/tdsmith), [Tom Schoonjans](https://github.com/tschoonj), [Uladzislau Shablinski](https://github.com/vladshablinsky) and [William Woodruff](https://github.com/woodruffw).

Former maintainers with significant contributions include [Baptiste Fontaine](https://github.com/bfontaine), [Xu Cheng](https://github.com/xu-cheng), [Martin Afanasjew](https://github.com/UniqMartin), [Dominyk Tiller](https://github.com/DomT4), [Brett Koonce](https://github.com/asparagui), [Charlie Sharpsteen](https://github.com/Sharpie), [Jack Nagel](https://github.com/jacknagel), [Adam Vandenberg](https://github.com/adamv) and Homebrew's creator: [Max Howell](https://github.com/mxcl).

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

## Sponsors
Our Xserve ESXi boxes for CI are hosted by [MacStadium](https://www.macstadium.com).

[![Powered by MacStadium](https://cloud.githubusercontent.com/assets/125011/22776032/097557ac-eea6-11e6-8ba8-eff22dfd58f1.png)](https://www.macstadium.com)

Our Jenkins CI installation is hosted by [DigitalOcean](https://m.do.co/c/7e39c35d5581).

![DigitalOcean](https://cloud.githubusercontent.com/assets/125011/26827038/4b7b5ade-4ab3-11e7-811b-fed3ab0e934d.png)

Our bottles (binary packages) are hosted by [Bintray](https://bintray.com/homebrew).

[![Downloads by Bintray](https://bintray.com/docs/images/downloads_by_bintray_96.png)](https://bintray.com/homebrew)

[Our website](https://brew.sh) is hosted by [Netlify](https://www.netlify.com).

[![Deploys by Netlify](https://www.netlify.com/img/global/badges/netlify-color-accent.svg)](https://www.netlify.com)

Secure password storage and syncing provided by [1Password for Teams](https://1password.com/teams/) by [AgileBits](https://agilebits.com)

[![AgileBits](https://da36klfizjv29.cloudfront.net/assets/branding/agilebits-fcca96e9b8e815c5c48c6b3e98156cb5.png)](https://agilebits.com)

Homebrew is a member of the [Software Freedom Conservancy](https://sfconservancy.org)

[![Software Freedom Conservancy](https://sfconservancy.org/img/conservancy_64x64.png)](https://sfconservancy.org)
