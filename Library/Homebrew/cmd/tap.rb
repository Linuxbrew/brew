#:  * `tap`:
#:    List all installed taps.
#:
#:  * `tap` [`--full`] [`--force-auto-update`] <user>`/`<repo> [<URL>]:
#:    Tap a formula repository.
#:
#:    With <URL> unspecified, taps a formula repository from GitHub using HTTPS.
#:    Since so many taps are hosted on GitHub, this command is a shortcut for
#:    `brew tap` <user>`/`<repo> `https://github.com/`<user>`/homebrew-`<repo>.
#:
#:    With <URL> specified, taps a formula repository from anywhere, using
#:    any transport protocol that `git` handles. The one-argument form of `tap`
#:    simplifies but also limits. This two-argument command makes no
#:    assumptions, so taps can be cloned from places other than GitHub and
#:    using protocols other than HTTPS, e.g., SSH, GIT, HTTP, FTP(S), RSYNC.
#:
#:    By default, the repository is cloned as a shallow copy (`--depth=1`), but
#:    if `--full` is passed, a full clone will be used. To convert a shallow copy
#:    to a full copy, you can retap passing `--full` without first untapping.
#:
#:    By default, only taps hosted on GitHub are auto-updated (for performance
#:    reasons). If `--force-auto-update` is passed, this tap will be auto-updated
#:    even if it is not hosted on GitHub.
#:
#:    `tap` is re-runnable and exits successfully if there's nothing to do.
#:    However, retapping with a different <URL> will cause an exception, so first
#:    `untap` if you need to modify the <URL>.
#:
#:  * `tap` `--repair`:
#:    Migrate tapped formulae from symlink-based to directory-based structure.
#:
#:  * `tap` `--list-pinned`:
#:    List all pinned taps.

require "cli_parser"

module Homebrew
  module_function

  def tap_args
    Homebrew::CLI::Parser.new do
      usage_banner <<~EOS
        `tap` [<options>] <user>`/`<repo> [<URL>]

        Tap a formula repository.

        List all installed taps when no arguments are passed.

        With <URL> unspecified, taps a formula repository from GitHub using HTTPS.
        Since so many taps are hosted on GitHub, this command is a shortcut for
        `brew tap` <user>`/`<repo> `https://github.com/`<user>`/homebrew-`<repo>.

        With <URL> specified, taps a formula repository from anywhere, using
        any transport protocol that `git` handles. The one-argument form of `tap`
        simplifies but also limits. This two-argument command makes no
        assumptions, so taps can be cloned from places other than GitHub and
        using protocols other than HTTPS, e.g., SSH, GIT, HTTP, FTP(S), RSYNC.
      EOS
      switch "--full",
        description: "Use a full clone when tapping a repository. By default, the repository is "\
                     "cloned as a shallow copy (`--depth=1`). To convert a shallow copy to a "\
                     "full copy, you can retap passing `--full` without first untapping."
      switch "--force-auto-update",
        description: "Auto-update tap even if it is not hosted on GitHub. By default, only taps "\
                     "hosted on GitHub are auto-updated (for performance reasons)."
      switch "--repair",
        description: "Migrate tapped formulae from symlink-based to directory-based structure."
      switch "--list-pinned",
        description: "List all pinned taps."
      switch "-q", "--quieter",
        description: "Suppress any warnings."
      switch :debug
    end
  end

  def tap
    tap_args.parse

    if args.repair?
      Tap.each(&:link_completions_and_manpages)
    elsif args.list_pinned?
      puts Tap.select(&:pinned?).map(&:name)
    elsif ARGV.named.empty?
      puts Tap.names
    else
      tap = Tap.fetch(ARGV.named.first)
      begin
        tap.install clone_target:      ARGV.named.second,
                    force_auto_update: force_auto_update?,
                    full_clone:        full_clone?,
                    quiet:             args.quieter?
      rescue TapRemoteMismatchError => e
        odie e
      rescue TapAlreadyTappedError, TapAlreadyUnshallowError # rubocop:disable Lint/HandleExceptions
      end
    end
  end

  def full_clone?
    args.full? || ARGV.homebrew_developer?
  end

  def force_auto_update?
    # if no relevant flag is present, return nil, meaning "no change"
    true if args.force_auto_update?
  end
end
