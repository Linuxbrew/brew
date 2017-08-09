#:  * `update-test` [`--commit=`<commit>] [`--before=`<date>] [`--to-tag`] [`--keep-tmp`]:
#:    Runs a test of `brew update` with a new repository clone.
#:
#:    If no arguments are passed, use `origin/master` as the start commit.
#:
#:    If `--commit=`<commit> is passed, use <commit> as the start commit.
#:
#:    If `--before=`<date> is passed, use the commit at <date> as the
#:    start commit.
#:
#:    If `--to-tag` is passed, set `HOMEBREW_UPDATE_TO_TAG` to test updating
#:    between tags.
#:
#:    If `--keep-tmp` is passed, retain the temporary directory containing
#:    the new repository clone.

module Homebrew
  module_function

  def update_test
    ENV["HOMEBREW_UPDATE_TEST"] = "1"

    if ARGV.include?("--to-tag")
      ENV["HOMEBREW_UPDATE_TO_TAG"] = "1"
      branch = "stable"
    else
      branch = "master"
    end

    cd HOMEBREW_REPOSITORY
    start_commit = if commit = ARGV.value("commit")
      commit
    elsif date = ARGV.value("before")
      Utils.popen_read("git", "rev-list", "-n1", "--before=#{date}", "origin/master").chomp
    elsif ARGV.include?("--to-tag")
      tags = Utils.popen_read("git", "tag", "--list", "--sort=-version:refname")
      previous_tag = tags.lines[1]
      previous_tag ||= begin
        if (HOMEBREW_REPOSITORY/".git/shallow").exist?
          safe_system "git", "fetch", "--tags", "--depth=1"
          tags = Utils.popen_read("git", "tag", "--list", "--sort=-version:refname")
        elsif OS.linux?
          tags = Utils.popen_read("git tag --list | sort -rV")
        end
        tags.lines[1]
      end
      previous_tag = previous_tag.to_s.chomp
      odie "Could not find previous tag in:\n#{tags}" if previous_tag.empty?
      previous_tag
    else
      Utils.popen_read("git", "rev-parse", "origin/master").chomp
    end
    odie "Could not find start commit!" if start_commit.empty?

    start_commit = Utils.popen_read("git", "rev-parse", start_commit).chomp
    odie "Could not find start commit!" if start_commit.empty?

    end_commit = Utils.popen_read("git", "rev-parse", "HEAD").chomp
    odie "Could not find end commit!" if end_commit.empty?

    puts "Start commit: #{start_commit}"
    puts "End   commit: #{end_commit}"

    mktemp("update-test") do |staging|
      staging.retain! if ARGV.keep_tmp?
      curdir = Pathname.new(Dir.pwd)

      oh1 "Setup test environment..."
      # copy Homebrew installation
      safe_system "git", "clone", "--local", "#{HOMEBREW_REPOSITORY}/.git", "."

      # set git origin to another copy
      safe_system "git", "clone", "--local", "--bare", "#{HOMEBREW_REPOSITORY}/.git", "remote.git"
      safe_system "git", "config", "remote.origin.url", "#{curdir}/remote.git"

      # force push origin to end_commit
      safe_system "git", "checkout", "-B", "master", end_commit
      safe_system "git", "push", "--force", "origin", "master"

      # set test copy to start_commit
      safe_system "git", "reset", "--hard", start_commit

      # update ENV["PATH"]
      ENV["PATH"] = "#{curdir}/bin:/usr/local/bin:/usr/bin:/bin"

      # run brew update
      oh1 "Running brew update..."
      safe_system "brew", "update", "--verbose"
      actual_end_commit = Utils.popen_read("git", "rev-parse", branch).chomp
      if start_commit != end_commit && start_commit == actual_end_commit
        raise <<-EOS.undent
          brew update didn't update #{branch}!
          Start commit:        #{start_commit}
          Expected end commit: #{end_commit}
          Actual end commit:   #{actual_end_commit}
        EOS
      end
    end
  end
end
