# Contributing to Linuxbrew
[Linuxbrew](https://github.com/Linuxbrew/linuxbrew) is a fork of [Homebrew](https://github.com/Homebrew/homebrew). Homebrew is merged into Linuxbrew roughly once per week. To contribute a new formula or a new version of an existing formula, please submit your pull request to Homebrew rather than to Linuxbrew. Patches to fix issues that you have reproduced on both Linuxbrew and Homebrew should be sent to Homebrew. Please send your pull request to Linuxbrew if you are in doubt.

Patches to fix issues particular to Linux should not affect the behaviour of the formula on Mac. Use `if OS.mac?` and `if OS.linux?` as necessary to preserve the existing behaviour on Mac.

# Contributing to Homebrew
First time contributing to Homebrew? Read our [Code of Conduct](https://github.com/Homebrew/brew/blob/master/CODEOFCONDUCT.md#code-of-conduct).

### Report a bug

* run `brew update` (twice)
* run and read `brew doctor`
* read [the Troubleshooting Checklist](https://github.com/Homebrew/brew/blob/master/share/doc/homebrew/Troubleshooting.md#troubleshooting)
* open an issue on the formula's repository

Thanks!
