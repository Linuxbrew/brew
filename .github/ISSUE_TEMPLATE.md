If Homebrew was updated on Aug 10-11th 2016 and `brew update` always says `Already up-to-date.` you need to run: `cd $(brew --repo); git fetch; git reset --hard origin/master; brew update`.

# Please follow the general troubleshooting steps first:

- [ ] Ran `brew update` and retried your prior step?
- [ ] Ran `brew doctor`, fixed as many issues as possible and retried your prior step?
- [ ] If you're seeing permission errors tried running `sudo chown -R $(whoami) $(brew --prefix)`?

_You can erase any parts of this template not applicable to your Issue._

### Bug reports:

Please replace this line with a brief summary of your issue.

### Feature Requests:

**Please note by far the quickest way to get a new feature into Cadfaelbrew is to file a [Pull Request](https://github.com/SuperNEMO-DBD/brew/blob/master/.github/CONTRIBUTING.md).**

