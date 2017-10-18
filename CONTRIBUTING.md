# Contributing to Linuxbrew

First time contributing to Linuxbrew? Read our [Code of Conduct](https://github.com/Linuxbrew/brew/blob/master/CODE_OF_CONDUCT.md#code-of-conduct).

[Linuxbrew](https://github.com/Linuxbrew/brew) is a fork of [Homebrew](https://github.com/Homebrew/brew). Homebrew/brew is merged into Linuxbrew/brew roughly once per week. If you have access to a macOS system and are able to test your changes there: please submit your pull request to Homebrew rather than to Linuxbrew. If not, please submit your pull requests to Linuxbrew. Patches to fix issues that you have reproduced on both Linuxbrew and Homebrew on macOS should be sent to Homebrew. Please send your pull request to Linuxbrew if you are in doubt.

Patches to fix issues particular to Linux should not affect the behaviour of the formula on macOS. Use `if OS.mac?` and `if OS.linux?` as necessary to preserve the existing behaviour on macOS.

### Report a bug

* run `brew update` (twice)
* run and read `brew doctor`
* read [the Troubleshooting Checklist](https://github.com/Linuxbrew/brew/blob/master/docs/Troubleshooting.md#troubleshooting)
* open an issue on the Linuxbrew formula's repository or on Linuxbrew/brew if it's not a formula-specific issue

### Propose a feature

* open an issue with a detailed description of your proposed feature, the motivation for it and alternatives considered. Please note we may close this issue or ask you to create a pull-request if this is not something we see as sufficiently high priority.

Thanks!
