# Troubleshooting

**Run `brew update` twice and `brew doctor` *before* creating an issue!**

This document will help you check for common issues and make sure your issue has not already been reported.

## Check for common issues

Follow these steps to fix common problems:

* Run `brew update` twice.
* Run `brew doctor` and fix all the warnings (**outdated Xcode/CLT and unbrewed dylibs are very likely to cause problems**).
* Check that **Command Line Tools for Xcode (CLT)** and **Xcode** are up to date.
* If commands fail with permissions errors, check the permissions of `/usr/local`'s subdirectories. If you’re unsure what to do, you can run `cd /usr/local && sudo chown -R $(whoami) bin etc include lib sbin share var opt Cellar Caskroom Frameworks`.
* Read through the [Common Issues](Common-Issues.md).

## Check to see if the issue has been reported

* Search the [issue tracker](https://github.com/Homebrew/homebrew-core/issues) to see if someone else has already reported the same issue.
* Make sure you search issues on the correct repository. If a formula that has failed to build is part of a non-homebrew-core tap or a cask is part of [Homebrew/cask](https://github.com/Homebrew/homebrew-cask/issues) check those issue trackers instead.

## Create an issue

If your problem hasn't been solved or reported, then create an issue:

0. Upload debugging information to a [Gist](https://gist.github.com):
  - If you had a formula-related problem: run `brew gist-logs <formula>` (where `<formula>` is the name of the formula).
  - If you encountered a non-formula problem: upload the output of `brew config` and `brew doctor` to a new [Gist](https://gist.github.com).
1. [Create a new issue](https://github.com/Homebrew/homebrew-core/issues/new/choose).
  - Give your issue a descriptive title which includes the formula name (if applicable) and the version of macOS you are using. For example, if a formula fails to build, title your issue "\<formula> failed to build on \<10.x>", where "\<formula>" is the name of the formula that failed to build, and "\<10.x>" is the version of macOS you are using.
  - Include the URL output by `brew gist-logs <formula>` (if applicable).
  - Include links to any additional Gists you may have created (such as for the output of `brew config` and `brew doctor`).
