# Contributing to Cadfaelbrew
[Cadfaelbrew](https://github.com/SuperNEMO-DBD/brew) is a fork of [Linuxbrew](https://github.com/Linuxbrew/brew). Linuxbrew is merged into Cadfaelbrew roughly once per month. To contribute a new formula or a new version of an existing formula, please submit your pull request to our [dedicated tap](https://github.com/SuperNEMO-DBD/homebrew-cadfael)

Patches to fix issues particular to Linux should not affect the behaviour of the formula on macOS. Use `if OS.mac?` and `if OS.linux?` as necessary to preserve the existing behaviour on macOS.

### Report a bug

* run `brew update` (twice)
* run and read `brew doctor`
* read [the Troubleshooting Checklist](https://github.com/SuperNEMO-DBD/brew/blob/master/share/doc/homebrew/Troubleshooting.md#troubleshooting)
* open an issue on the formula's repository or on Linuxbrew/brew if it's not a formula-specific issue

### Propose a feature

* Please open an issue (or pull request if you have an implementation) with your change proposal.

### Propose a feature

* open an issue with a detailed description of your proposed feature, the motivation for it and alternatives considered. Please note we may close this issue or ask you to create a pull-request if this is not something we see as sufficiently high priority.

Thanks!
