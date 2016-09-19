#:  * `update-test` [`--commit=<sha1>`] [`--before=<date>`] [`--keep-tmp`]:
#:    Runs a test of `brew update` with a new repository clone.
#:
#:    If no arguments are passed, use `origin/master` as the start commit.
#:
#:    If `--commit=<sha1>` is passed, use `<sha1>` as the start commit.
#:
#:    If `--before=<date>` is passed, use the commit at `<date>` as the
#:    start commit.
#:
#:    If `--keep-tmp` is passed, retain the temporary directory containing
#:    the new repository clone.

module Homebrew
  def update_test
    cd HOMEBREW_REPOSITORY
    start_sha1 = if commit = ARGV.value("commit")
      commit
    elsif date = ARGV.value("before")
      Utils.popen_read("git", "rev-list", "-n1", "--before=#{date}", "origin/master").chomp
    else
      Utils.popen_read("git", "rev-parse", "origin/master").chomp
    end
    start_sha1 = Utils.popen_read("git", "rev-parse", start_sha1).chomp
    end_sha1 = Utils.popen_read("git", "rev-parse", "HEAD").chomp

    puts "Start commit: #{start_sha1}"
    puts "End   commit: #{end_sha1}"

    mktemp("update-test") do |staging|
      staging.retain! if ARGV.keep_tmp?
      curdir = Pathname.new(Dir.pwd)

      oh1 "Setup test environment..."
      # copy Homebrew installation
      safe_system "git", "clone", "--local", "#{HOMEBREW_REPOSITORY}/.git", "."

      # set git origin to another copy
      safe_system "git", "clone", "--local", "--bare", "#{HOMEBREW_REPOSITORY}/.git", "remote.git"
      safe_system "git", "config", "remote.origin.url", "#{curdir}/remote.git"

      # force push origin to end_sha1
      safe_system "git", "checkout", "--force", "master"
      safe_system "git", "reset", "--hard", end_sha1
      safe_system "git", "push", "--force", "origin", "master"

      # set test copy to start_sha1
      safe_system "git", "reset", "--hard", start_sha1

      # update ENV["PATH"]
      ENV["PATH"] = "#{curdir}/bin:/usr/local/bin:/usr/bin:/bin"

      # run brew update
      oh1 "Running brew update..."
      safe_system "brew", "update", "--verbose"
      actual_end_sha1 = Utils.popen_read("git", "rev-parse", "master").chomp
      if start_sha1 != end_sha1 && start_sha1 == actual_end_sha1
        raise <<-EOS.undent
          brew update didn't update master!
          Start commit:        #{start_sha1}
          Expected end commit: #{end_sha1}
          Actual end commit:   #{actual_end_sha1}
        EOS
      end
    end
  end
end
