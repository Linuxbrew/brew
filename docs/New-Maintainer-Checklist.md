# New Maintainer Checklist

**This is a guide used by existing maintainers to invite new maintainers. You might find it interesting but there's nothing here users should have to know.**

There's someone who has been making consistently high-quality contributions to Homebrew for a long time and shown themselves able to make slightly more advanced contributions than just e.g. formula updates? Let's invite them to be a maintainer!

First, send them the invitation email:

```
The Homebrew team and I really appreciate your help on issues, pull requests and
your contributions around $THEIR_CONTRIBUTIONS.

We would like to invite you to have commit access and be a Homebrew maintainer.
If you agree to be a maintainer, you should spend a significant proportion of
the time you are working on Homebrew fixing user-reported issues, resolving any
issues that arise from your code in a timely fashion and reviewing user
contributions. You should also be making contributions to Homebrew every month
unless you are ill or on vacation (and please let another maintainer know if
that's the case so we're aware you won't be able to help while you are out).
You will need to watch Homebrew/brew and/or Homebrew/homebrew-core. If you're
no longer able to perform all of these tasks, please continue to contribute to
Homebrew, but we will ask you to step down as a maintainer.

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
    - anything else you haven't read on https://docs.brew.sh

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

After a month-long trial period with no problems make them [owners on the Homebrew GitHub organisation](https://github.com/orgs/Homebrew/people) and add them to [Homebrew's README](https://github.com/Homebrew/brew/edit/master/README.md). If there are problems, ask them to step down as a maintainer and revoke their access to the above.

Now sit back, relax and let the new maintainers handle more of our contributions.
