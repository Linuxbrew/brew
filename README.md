# Homebrew
[![GitHub release](https://img.shields.io/github/release/Homebrew/brew.svg)](https://github.com/Homebrew/brew/releases)

Features, usage and installation instructions are [summarised on the homepage](https://brew.sh). Terminology (e.g. the difference between a Cellar, Tap, Cask and so forth) is [explained here](https://docs.brew.sh/Formula-Cookbook#homebrew-terminology).

## What Packages Are Available?
1. Type `brew search` for a list.
2. Or visit [formulae.brew.sh](https://formulae.brew.sh) to browse packages online.
3. Or use `brew search --desc <keyword>` to browse packages from the command line.

## More Documentation
`brew help`, `man brew` or check [our documentation](https://docs.brew.sh/).

## Troubleshooting
First, please run `brew update` and `brew doctor`.

Second, read the [Troubleshooting Checklist](https://docs.brew.sh/Troubleshooting).

**If you don't read these it will take us far longer to help you with your problem.**

## Contributing
[![Azure Pipelines](https://img.shields.io/vso/build/Homebrew/56a87eb4-3180-495a-9117-5ed6c79da737/1.svg)](https://dev.azure.com/Homebrew/Homebrew/_build/latest?definitionId=1)
[![Codecov](https://img.shields.io/codecov/c/github/Homebrew/brew.svg)](https://codecov.io/gh/Homebrew/brew)

We'd love you to contribute to Homebrew. First, please read our [Contribution Guide](CONTRIBUTING.md) and [Code of Conduct](CODE_OF_CONDUCT.md#code-of-conduct).

We explicitly welcome contributions from people who have never contributed to open-source before: we were all beginners once! We can help build on a partially working pull request with the aim of getting it merged. We are also actively seeking to diversify our contributors and especially welcome contributions from women from all backgrounds and people of colour.

A good starting point for contributing is running `brew audit --strict` with some of the packages you use (e.g. `brew audit --strict wget` if you use `wget`) and then read through the warnings, try to fix them until `brew audit --strict` shows no results and [submit a pull request](https://docs.brew.sh/How-To-Open-a-Homebrew-Pull-Request). If no formulae you use have warnings you can run `brew audit --strict` without arguments to have it run on all packages and pick one.

Alternatively, for something more substantial, check out one of the issues labeled `help wanted` in [Homebrew/brew](https://github.com/homebrew/brew/issues?q=is%3Aopen+is%3Aissue+label%3A%22help+wanted%22) or [Homebrew/homebrew-core](https://github.com/homebrew/homebrew-core/issues?q=is%3Aopen+is%3Aissue+label%3A%22help+wanted%22).

Good luck!

## Security
Please report security issues to our [HackerOne](https://hackerone.com/homebrew/).

## Who Are You?
Homebrew's lead maintainer is [Mike McQuaid](https://github.com/mikemcquaid).

Homebrew's project leadership committee is [Mike McQuaid](https://github.com/mikemcquaid), [JCount](https://github.com/jcount), [Misty De Meo](https://github.com/mistydemeo) and [Markus Reiter](https://github.com/reitermarkus).

Homebrew/brew's other current maintainers are [Claudia](https://github.com/claui), [Michka Popoff](https://github.com/imichka), [Shaun Jackman](https://github.com/sjackman), [Chongyu Zhu](https://github.com/lembacon), [Vitor Galvao](https://github.com/vitorgalvao), [JCount](https://github.com/jcount), [Misty De Meo](https://github.com/mistydemeo), [Gautham Goli](https://github.com/GauthamGoli), [Markus Reiter](https://github.com/reitermarkus), [Steven Peters](https://github.com/scpeters), [Jonathan Chang](https://github.com/jonchang) and [William Woodruff](https://github.com/woodruffw).

Homebrew/brew's Linux support (and Linuxbrew) maintainers are [Michka Popoff](https://github.com/imichka) and [Shaun Jackman](https://github.com/sjackman).

Homebrew/homebrew-core's other current maintainers are [Claudia](https://github.com/claui), [Michka Popoff](https://github.com/imichka), [Shaun Jackman](https://github.com/sjackman), [Chongyu Zhu](https://github.com/lembacon), [Izaak Beekman](https://github.com/zbeekman), [Sean Molenaar](https://github.com/SMillerDev), [Jan Viljanen](https://github.com/javian), [Jason Tedor](https://github.com/jasontedor), [Viktor Szakats](https://github.com/vszakats), [FX Coudert](https://github.com/fxcoudert), [Thierry Moisan](https://github.com/moisan), [Steven Peters](https://github.com/scpeters), [JCount](https://github.com/jcount), [Misty De Meo](https://github.com/mistydemeo) and [Tom Schoonjans](https://github.com/tschoonj).

Former maintainers with significant contributions include [commitay](https://github.com/commitay), [Dominyk Tiller](https://github.com/DomT4), [Tim Smith](https://github.com/tdsmith), [Baptiste Fontaine](https://github.com/bfontaine), [Xu Cheng](https://github.com/xu-cheng), [Martin Afanasjew](https://github.com/UniqMartin), [Brett Koonce](https://github.com/asparagui), [Charlie Sharpsteen](https://github.com/Sharpie), [Jack Nagel](https://github.com/jacknagel), [Adam Vandenberg](https://github.com/adamv), [Andrew Janke](https://github.com/apjanke), [Alex Dunn](https://github.com/dunn), [neutric](https://github.com/neutric), [Tomasz Pajor](https://github.com/nijikon), [Uladzislau Shablinski](https://github.com/vladshablinsky), [Alyssa Ross](https://github.com/alyssais), [ilovezfs](https://github.com/ilovezfs) and Homebrew's creator: [Max Howell](https://github.com/mxcl).

## Community
- [discourse.brew.sh (forum)](https://discourse.brew.sh)
- [freenode.net\#machomebrew (IRC)](irc://irc.freenode.net/#machomebrew)
- [@MacHomebrew (Twitter)](https://twitter.com/MacHomebrew)

## License
Code is under the [BSD 2-clause "Simplified" License](LICENSE.txt).
Documentation is under the [Creative Commons Attribution license](https://creativecommons.org/licenses/by/4.0/).

## Donations
Homebrew is a non-profit project run entirely by unpaid volunteers. We need your funds to pay for software, hardware and hosting around continuous integration and future improvements to the project. Every donation will be spent on making Homebrew better for our users.

Please consider a regular donation through Patreon:

[![Donate with Patreon](https://img.shields.io/badge/patreon-donate-green.svg)](https://www.patreon.com/homebrew)

Alternatively, if you'd rather make a one-off payment:

- [Donate with PayPal](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=V6ZE57MJRYC8L)
- Donate by USA $ check from a USA bank:
  - Make check payable to "Software Freedom Conservancy, Inc." and place "Directed donation: Homebrew" in the memo field. Checks should then be mailed to:
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

Secure password storage and syncing is provided by [1Password for Teams](https://1password.com/teams/) by [AgileBits](https://agilebits.com).

[![AgileBits](https://da36klfizjv29.cloudfront.net/assets/branding/agilebits-fcca96e9b8e815c5c48c6b3e98156cb5.png)](https://agilebits.com)

Homebrew is a member of the [Software Freedom Conservancy](https://sfconservancy.org).

[![Software Freedom Conservancy](https://sfconservancy.org/img/conservancy_64x64.png)](https://sfconservancy.org)
