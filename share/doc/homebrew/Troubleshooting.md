# Troubleshooting
**Run `brew update` (twice) and `brew doctor` *before* creating an issue!**

When creating a formula-related issue please include the link output by running:

```shell
brew gist-logs <formula>
```

## Check for common issues
* Run `brew update` (twice).
* Run `brew doctor` and fix all the warnings (**outdated Xcode/CLT and unbrewed dylibs are very likely to cause problems**).
* Read through the [Common Issues](Common-Issues.md).
* If you’re installing something Java-related, maybe you need to install Java (`brew cask install java`)?
* Check that **Command Line Tools for Xcode (CLT)** and/or **Xcode** are up to date.
* If things fail with permissions errors, check the permissions of `/usr/local`'s subdirectories. If you’re unsure what to do, you can `cd /usr/local && sudo chown -R $(whoami) bin etc include lib sbin share var Frameworks`.

## Check to see if the issue has been reported
* Check the [issue tracker](https://github.com/Linuxbrew/homebrew-core/issues) to see if someone else has already reported the same issue.
* Make sure you check issues on the correct repository. If the formula that failed to build is part of a tap like [homebrew/science](https://github.com/Homebrew/homebrew-science) or [homebrew/dupes](https://github.com/Homebrew/homebrew-dupes) check there instead.

## Create an issue
0. Upload debugging information to a [Gist](https://gist.github.com):
  - If you had a formula error: run `brew gist-logs <formula>` (where `<formula>` is the name of the formula that failed to build).
  - If you encountered a non-formula bug: upload the output of `brew config` and `brew doctor` to a new [Gist](https://gist.github.com).
1. [Create a new issue](https://github.com/Linuxbrew/homebrew-core/issues/new) titled "\<formula name> failed to build on \<distro>", where `<formula name>` is the name of the formula that failed to build, and `<distro>` is the distribution of Linux you are using and including the link output by `brew gist-logs`
