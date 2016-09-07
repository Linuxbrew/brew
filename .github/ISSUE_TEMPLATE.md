If Homebrew was updated on Aug 10-11th 2016 and `brew update` always says `Already up-to-date.` you need to run: `cd "$(brew --repo)" && git fetch && git reset --hard origin/master && brew update`.

# Please follow the general troubleshooting steps first:

- [ ] Ran `brew update` and retried your prior step?
- [ ] Ran `brew doctor`, fixed as many issues as possible and retried your prior step?
- [ ] If you're seeing permission errors tried running `sudo chown -R $(whoami) $(brew --prefix)`?

_You can erase any parts of this template not applicable to your Issue._

### Bug reports:

Please replace this line with a brief summary of your issue.

### Propose a feature:

Instead of creating an issue here, please create a pull request with your change proposal in the [Homebrew Evolution](https://github.com/Homebrew/brew-evolution) repository using the [proposal template](https://github.com/Homebrew/brew-evolution/blob/master/proposal_template.md).
