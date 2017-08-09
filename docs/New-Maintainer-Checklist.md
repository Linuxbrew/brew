# New Maintainer Checklist

**This is a guide used by existing maintainers to invite new maintainers. You might find it interesting but there's nothing here users should have to know.**

So, there's someone who has been making consistently high-quality contributions to Homebrew for a long time and shown themselves able to make slightly more advanced contributions than just e.g. formula updates? Let's invite them to be a maintainer!

First, send them the invitation email:

```
The Homebrew team and I really appreciate your help on issues, pull requests and
your contributions around $THEIR_CONTRIBUTIONS.

We would like to invite you to have commit access. There are no obligations,
but we'd appreciate your continuing help in keeping on top of contributions.
The easiest way to do this is to watch the Homebrew/brew and
Homebrew/homebrew-core repositories on GitHub to provide help and code review
and to pull suitable changes.

A few requests:

- please make pull requests on any changes to Homebrew/brew code or any
  non-trivial (e.g. not a test or audit improvement or version bump) changes
  to formulae code and don't merge them unless you get at least one approval
  and passing tests.
- use `brew pull` for formulae changes that require new bottles or change
  multiple formulae and let it auto-close issues wherever possible (it may
  take ~5m). When this isn't necessary use GitHub's "Merge pull request"
  button in "create a merge commit" mode for Homebrew/brew or "squash and
  merge" for a single formulae change. If in doubt, check with e.g. GitX that
  you've not accidentally added merge commits
- still create your branches on your fork rather than in the main repository.
  Note GitHub's UI will create edits and reverts on the main repository if you
  make edits or click revert on the Homebrew/brew repository rather than your
  own fork.
- if still in doubt please ask for help and we'll help you out
- please read:
    - https://docs.brew.sh/Brew-Test-Bot-For-Core-Contributors.html
    - https://docs.brew.sh/Maintainer-Guidelines.html
    - possibly everything else on https://docs.brew.sh

How does that sound?

Thanks for all your work so far!
```

If they accept, follow a few steps to get them set up:

- Invite them to the [**@Homebrew/maintainers** team](https://github.com/orgs/Homebrew/teams/maintainers) to give them write access to all repositories (but don't make them owners yet). They will need to enable [GitHub's Two Factor Authentication](https://help.github.com/articles/about-two-factor-authentication/).
- Ask them to sign in to [Bintray](https://bintray.com) using their GitHub account and they should auto-sync to [Bintray's Homebrew organisation](https://bintray.com/homebrew/organization/edit/members) as a member so they can publish new bottles
- Add them to the [Jenkins' GitHub Authorization Settings admin user names](https://jenkins.brew.sh/configureSecurity/) so they can adjust settings and restart jobs
- Add them to the [Jenkins' GitHub Pull Request Builder admin list](https://jenkins.brew.sh/configure) to enable `@BrewTestBot test this please` for them
- Invite them to the [`homebrew-maintainers` private maintainers mailing list](https://lists.sfconservancy.org/mailman/admin/homebrew-maintainers/members/add)
- Invite them to the [`machomebrew` private maintainers Slack](https://machomebrew.slack.com/admin/invites)
- Invite them to the [`homebrew` private maintainers 1Password](https://homebrew.1password.com/signin)
- Invite them to [Google Analytics](https://analytics.google.com/analytics/web/?authuser=1#management/Settings/a76679469w115400090p120682403/%3Fm.page%3DAccountUsers/)
- Add them to [Homebrew's README](https://github.com/Homebrew/brew/edit/master/README.md)

After a few weeks/months with no problems consider making them [owners on the Homebrew GitHub organisation](https://github.com/orgs/Homebrew/people).

Now sit back, relax and let the new maintainers handle more of our contributions.
