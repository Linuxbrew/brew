# Contributing to Linuxbrew:

To contribute a new formula or a new version of an existing formula, please submit your pull request to [Homebrew](https://github.com/Homebrew/homebrew) rather than to Linuxbrew. Patches to fix issues that you have reproduced on both Linuxbrew and Homebrew should be sent to Homebrew. Please send your pull request to Linuxbrew if you are in doubt.

Patches to fix issues particular to Linux should not affect the behaviour of the formula on Mac. Use `if OS.mac?` and `if OS.linux?` as necessary to preserve the existing behaviour on Mac. For example, to add a new dependency that is not necessary on Mac:

```ruby
depends_on "zlib" unless OS.mac?
```

### All Submissions:

_You can erase any parts of this template not applicable to your Pull Request._

- [ ] Have you followed the guidelines in our [Contributing](https://github.com/Linuxbrew/linuxbrew/blob/master/.github/CONTRIBUTING.md) document?
- [ ] Have you checked to ensure there aren't other open [Pull Requests](https://github.com/Linuxbrew/linuxbrew/pulls) for the same update/change?
+ [ ] Have you included a log of the failed build without your patch using `brew gist-logs <formula>`?
- [ ] Does your submission pass
`brew audit --strict <formula>` (where `<formula>` is the name of the formula you're submitting)?
- [ ] Have you built your formula locally prior to submission with `brew install <formula>`?

### Changes to Linuxbrew's Core:

- [ ] Have you added an explanation of what your changes do and why you'd like us to include them?
- [ ] Have you written new tests for your core changes, as applicable? [Here's an example](https://github.com/Homebrew/homebrew/pull/49031) if you'd like one.
- [ ] Have you successfully ran `brew tests` with your changes locally?
