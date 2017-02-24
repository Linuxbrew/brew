# Homebrew
Features, usage and installation instructions are [summarised on the homepage](https://brew.sh). Terminology (e.g. the difference between a Cellar, Tap, Cask and so forth) is [explained here](docs/Formula-Cookbook.md#homebrew-terminology).

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
`brew help`, `man brew` or check [our documentation](http://docs.brew.sh/).

## Troubleshooting
First, please run `brew update` and `brew doctor`.

Second, read the [Troubleshooting Checklist](http://docs.brew.sh/Troubleshooting.html).

**If you don't read these it will take us far longer to help you with your problem.**

## Contributing
We'd love you to contribute to Homebrew. First, please read our [Contribution Guide](https://github.com/Homebrew/brew/blob/master/CONTRIBUTING.md) and [Code of Conduct](https://github.com/Homebrew/brew/blob/master/CODEOFCONDUCT.md#code-of-conduct).

We explicitly welcome contributions from people who have never contributed to open-source before: we were all beginners once! We can help build on a partially working pull request with the aim of getting it merged. We are also actively seeking to diversify our contributors and especially welcome contributions from women from all backgrounds and people of colour.

A good starting point for contributing is running `brew audit` (or `brew audit --strict`) with some of the packages you use (e.g. `brew audit wget` if you use `wget`) and then read through the warnings, try to fix them until `brew audit` shows no results and [submit a pull request](http://docs.brew.sh/How-To-Open-a-Homebrew-Pull-Request.html). If no formulae you use have warnings you can run `brew audit` without arguments to have it run on all packages and pick one. Good luck!

## Security
Please report security issues to security@brew.sh.

This is our PGP key which is valid until May 24, 2017.
* Key ID: `0xE33A3D3CCE59E297`
* Fingerprint: `C657 8F76 2E23 441E C879  EC5C E33A 3D3C CE59 E297`
* Full key: https://keybase.io/homebrew/key.asc

## Who Are You?
Homebrew's lead maintainer is [Mike McQuaid](https://github.com/mikemcquaid).

Homebrew's current maintainers are [Misty De Meo](https://github.com/mistydemeo), [Andrew Janke](https://github.com/apjanke), [Tomasz Pajor](https://github.com/nijikon), [Josh Hagins](https://github.com/jawshooah), [Baptiste Fontaine](https://github.com/bfontaine), [Markus Reiter](https://github.com/reitermarkus), [ilovezfs](https://github.com/ilovezfs), [Tom Schoonjans](https://github.com/tschoonj), [Uladzislau Shablinski](https://github.com/vladshablinsky), [Tim Smith](https://github.com/tdsmith) and [Alex Dunn](https://github.com/dunn).

Former maintainers with significant contributions include [Xu Cheng](https://github.com/xu-cheng), [Martin Afanasjew](https://github.com/UniqMartin), [Dominyk Tiller](https://github.com/DomT4), [Brett Koonce](https://github.com/asparagui), [Jack Nagel](https://github.com/jacknagel), [Adam Vandenberg](https://github.com/adamv) and Homebrew's creator: [Max Howell](https://github.com/mxcl).

## Community
- [discourse.brew.sh (forum)](http://discourse.brew.sh)
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
