If Homebrew was updated on Aug 10-11th 2016 and `brew update` always says `Already up-to-date.` you need to run: `cd "$(brew --repo)" && git fetch && git reset --hard origin/master && brew update`.

# Please follow the general troubleshooting steps first:

- [ ] Ran `brew update` and retried your prior step?
- [ ] Ran `brew doctor`, fixed as many issues as possible and retried your prior step?
- [ ] Confirmed this is problem with Linuxbrew/brew and not specific formulae? If it's a formulae-specific problem please file this issue at https://github.com/Linuxbrew/homebrew-core/issues/new

_You can erase any parts of this template not applicable to your Issue._

### Bug reports:

Please replace this section with a brief summary of your issue **AND** the output of `brew config` and `brew doctor`. Please note we may immediately close your issue without comment if you do not fill out the issue template and provide the requested information.

### Propose a feature:

Please replace this section with a detailed description of your proposed feature, the motivation for it and alternatives considered. Please note we may close this issue or ask you to create a pull-request if it's something we're not actively planning to work on.
