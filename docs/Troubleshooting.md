# Troubleshooting

**Run `brew update` twice and `brew doctor` *before* creating an issue!**

This document will help you check for common issues and make sure your issue has not already been reported.


## Check for common issues

Follow these steps to fix common problems:

* Run `brew update` twice.
* Run `brew doctor` and fix all the warnings (**outdated Xcode/CLT and unbrewed dylibs are very likely to cause problems**).
* Check that **Command Line Tools for Xcode (CLT)** and **Xcode** are up to date.
* If commands fail with permissions errors, check the permissions of `/usr/local`'s subdirectories. If you’re unsure what to do, you can run `cd /usr/local && sudo chown -R $(whoami) bin etc include lib sbin share var Frameworks`.
* Read through the [Common Issues](Common-Issues.md).
* If you’re installing something Java-related, make sure you have installed Java (you can run `brew cask install java`).


## Check to see if the issue has been reported
* Check the [issue tracker](https://github.com/Linuxbrew/homebrew-core/issues) to see if someone else has already reported the same issue.
* Make sure you check issues on the correct repository. If the formula that failed to build is part of a tap like [homebrew/science](https://github.com/Homebrew/homebrew-science) or [homebrew/dupes](https://github.com/Homebrew/homebrew-dupes) check there instead.

## Create an issue

If your problem hasn't been solved or reported, then create an issue:

0. Upload debugging information to a [Gist](https://gist.github.com):
  - If you had a formula-related problem: run `brew gist-logs <formula>` (where `<formula>` is the name of the formula).
  - If you encountered a non-formula problem: upload the output of `brew config` and `brew doctor` to a new [Gist](https://gist.github.com).
1. [Create a new issue](https://github.com/Linuxbrew/homebrew-core/issues/new)
  - Give your issue the title "\<formula name> failed to build on \<distro>", where `<formula name>` is the name of the formula that failed to build, and `<distro>` is the distribution of Linux you are using.
  - Include the URL output by `brew gist-logs <formula>` (if applicable).
  - Include links to any additional Gists you may have created (such as for the output of `brew config` and `brew doctor`).
