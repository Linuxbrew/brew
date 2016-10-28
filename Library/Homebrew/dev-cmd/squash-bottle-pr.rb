require "formula"

module Homebrew
  # Squash the last two commits of build-bottle-pr.
  # Usage:
  #    brew build-bottle-pr foo
  #    brew pull --bottle 123
  #    brew squash-bottle-pr
  def squash_bottle_pr
    head = `git rev-parse HEAD`.chomp
    formula = `git log -n1 --pretty=format:%s`.split(":").first
    file = Formula[formula].path
    marker = "Build a bottle for Linuxbrew"
    safe_system "git", "reset", "--hard", "HEAD~2"
    safe_system "git", "merge", "--squash", head
    # The argument to -i is required for BSD sed.
    safe_system "sed", "-iorig", "-e", "/^#.*: #{marker}$/d", file
    rm_f file.to_s + "orig"

    git_editor = ENV["GIT_EDITOR"]
    ENV["GIT_EDITOR"] = "sed -n -i -e 's/.*#{marker}//p;s/^    //p'"
    safe_system "git", "commit", file
    ENV["GIT_EDITOR"] = git_editor

    safe_system "git", "show" if ARGV.verbose?
  end
end
