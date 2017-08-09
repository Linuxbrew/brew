# Maintainer Guidelines

**This guide is for maintainers.** These special people have **write
access** to Homebrew’s repository and help merge the contributions of
others. You may find what is written here interesting, but it’s
definitely not a beginner’s guide.

Maybe you were looking for the [Formula Cookbook](Formula-Cookbook.md)?

## Quick checklist

This is all that really matters:
- Ensure the name seems reasonable.
- Add aliases.
- Ensure it uses `keg_only :provided_by_macos` if it already comes with macOS.
- Ensure it is not a library that can be installed with
  [gem](https://en.wikipedia.org/wiki/RubyGems),
  [cpan](https://en.wikipedia.org/wiki/Cpan) or
  [pip](https://pip.pypa.io/en/stable/).
- Ensure that any dependencies are accurate and minimal. We don't need to
  support every possible optional feature for the software.
- Use the GitHub squash & merge workflow where bottles aren't required.
- Use `brew pull` otherwise, which adds messages to auto-close pull requests and pull bottles built by the Brew Test Bot.
- Thank people for contributing.

Checking dependencies is important, because they will probably stick around
forever. Nobody really checks if they are necessary or not. Use the
`:optional` and `:recommended` modifiers as appropriate.

Depend on as little stuff as possible. Disable X11 functionality by default.
For example, we build Wireshark, but not the heavy GTK/Qt GUI by default.

Homebrew is about Unix software. Stuff that builds to an `.app` should
probably be in Homebrew Cask instead.

### Naming
The name is the strictest item, because avoiding a later name change is
desirable.

Choose a name that’s the most common name for the project.
For example, we initially chose `objective-caml` but we should have chosen `ocaml`.
Choose what people say to each other when talking about the project.

Add other names as aliases as symlinks in `Aliases` in the tap root. Ensure the
name referenced on the homepage is one of these, as it may be different and have
underscores and hyphens and so on.

We now accept versioned formulae as long as they [meet the requirements](Versions.md).

### Merging, rebasing, cherry-picking
Merging should be done in the `Homebrew/brew` repository to preserve history & GPG commit signing,
and squash/merge via GitHub should be used for formulae where those formulae
don't need bottles or the change does not require new bottles to be pulled.
Otherwise, you should use `brew pull` (or `rebase`/`cherry-pick` contributions).

Don’t `rebase` until you finally `push`. Once `master` is pushed, you can’t
`rebase`: **you’re a maintainer now!**

Cherry-picking changes the date of the commit, which kind of sucks.

Don’t `merge` unclean branches. So if someone is still learning `git` and
their branch is filled with nonsensical merges, then `rebase` and squash
the commits. Our main branch history should be useful to other people,
not confusing.

### Testing
We need to at least check that it builds. Use the [Brew Test Bot](Brew-Test-Bot.md) for this.

Verify the formula works if possible. If you can’t tell (e.g. if it’s a
library) trust the original contributor, it worked for them, so chances are it
is fine. If you aren’t an expert in the tool in question, you can’t really
gauge if the formula installed the program correctly. At some point an expert
will come along, cry blue murder that it doesn’t work, and fix it. This is how
open source works. Ideally, request a `test do` block to test that
functionality is consistently available.

If the formula uses a repository, then the `url` parameter should have a
tag or revision. `url`s have versions and are stable (not yet
implemented!).

## Common “gotchas”
1.  [Ensure you have set your username and email address
    properly](https://help.github.com/articles/setting-your-email-in-git/)
2.  Sign off cherry-picks if you amended them ([GitX-dev](https://github.com/rowanj/gitx)
    can do this, otherwise there is a command-line flag for it)
3.  If the commit fixes a bug, use “Fixes \#104” syntax to close the bug
    report and link to the commit

### Duplicates
We now accept stuff that comes with macOS as long as it uses `keg_only :provided_by_macos` to be keg-only by default.

### Add comments
It may be enough to refer to an issue ticket, but make sure changes are clear so that
if you came to them unaware of the surrounding issues they would make sense
to you. Many times on other projects I’ve seen code removed because the
new guy didn’t know why it was there. Regressions suck.

### Don’t allow bloated diffs
Amend a cherry-pick to remove commits that are only changes in
whitespace. They are not acceptable because our history is important and
`git blame` should be useful.

Whitespace corrections (to Ruby standard etc.) are allowed (in fact this
is a good opportunity to do it) provided the line itself has some kind
of modification that is not whitespace in it. But be careful about
making changes to inline patches—make sure they still apply.
