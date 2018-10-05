# Brew Test Bot For Core Contributors

If a build has run and passed on `brew test-bot` then it can be used to quickly bottle formulae.

There are two types of Jenkins jobs you will interact with:

## [Homebrew Core Pull Requests](https://jenkins.brew.sh/job/Homebrew%20Core%20Pull%20Requests/)
This job automatically builds any pull requests submitted to Homebrew/homebrew-core. On success or failure it updates the pull request status (see more details on the [main Brew Test Bot documentation page](Brew-Test-Bot.md)). On a successful build it automatically uploads bottles.

## [Homebrew Testing](https://jenkins.brew.sh/job/Homebrew%20Testing/)
This job is manually triggered to run [`brew test-bot`](https://github.com/Homebrew/homebrew-test-bot/blob/master/cmd/brew-test-bot.rb) with user-specified parameters. On a successful build it automatically uploads bottles.

You can manually start this job with parameters to run [`brew test-bot`](https://github.com/Homebrew/homebrew-test-bot/blob/master/cmd/brew-test-bot.rb) with the same parameters. It's often useful to pass a pull request URL, a commit URL, a commit SHA-1 and/or formula names to have the Brew Test Bot test them, report the results and produce bottles.

## Bottling
To pull and bottle a pull request with `brew pull`:

1. Ensure the job has already completed successfully.
2. Run `brew pull --bottle 12345` where `12345` is the pull request number (or URL). If it complains about a missing URL with `BrewTestBot` in it then the bottles have not finished uploading yet; wait and try again later.
3. Run `git push` to push the commits.

To bottle a test build:

1. Ensure the job has already completed successfully.
2. Run `brew pull --bottle https://jenkins.brew.sh/job/Homebrew%20Testing/1234/` where `https://jenkins.brew.sh/job/Homebrew%20Testing/1234/` is the testing build URL in Jenkins.
3. Run `git push` to push the commits.
