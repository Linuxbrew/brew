#:  * `tap`:
#:    List all installed taps.
#:
#:  * `tap` [`--full`] <user>`/`<repo> [<URL>]:
#:    Tap a formula repository.
#:
#:    With <URL> unspecified, taps a formula repository from GitHub using HTTPS.
#:    Since so many taps are hosted on GitHub, this command is a shortcut for
#:    `tap <user>/<repo> https://github.com/<user>/homebrew-<repo>`.
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
#:    `tap` is re-runnable and exits successfully if there's nothing to do.
#:    However, retapping with a different <URL> will cause an exception, so first
#:    `untap` if you need to modify the <URL>.
#:
#:  * `tap` `--repair`:
#:    Migrate tapped formulae from symlink-based to directory-based structure.
#:
#:  * `tap` `--list-official`:
#:    List all official taps.
#:
#:  * `tap` `--list-pinned`:
#:    List all pinned taps.

require "tap"

module Homebrew
  module_function

  def tap
    if ARGV.include? "--repair"
      Tap.each(&:link_completions_and_manpages)
    elsif ARGV.include? "--list-official"
      require "official_taps"
      puts OFFICIAL_TAPS.map { |t| "homebrew/#{t}" }
    elsif ARGV.include? "--list-pinned"
      puts Tap.select(&:pinned?).map(&:name)
    elsif ARGV.named.empty?
      puts Tap.names
    else
      tap = Tap.fetch(ARGV.named[0])
      begin
        tap.install clone_target: ARGV.named[1],
                    full_clone: full_clone?,
                    quiet: ARGV.quieter?
      rescue TapRemoteMismatchError => e
        odie e
      rescue TapAlreadyTappedError, TapAlreadyUnshallowError
        # Do nothing.
      end
    end
  end

  def full_clone?
    ARGV.include?("--full") || ARGV.homebrew_developer?
  end
end
