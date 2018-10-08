require "utils/git"
require "utils/popen"

module GitRepositoryExtension
  def git?
    join(".git").exist?
  end

  def git_origin
    return unless git? && Utils.git_available?

    Utils.popen_read("git", "config", "--get", "remote.origin.url", chdir: self).chomp.presence
  end

  def git_origin=(origin)
    return unless git? && Utils.git_available?

    safe_system "git", "remote", "set-url", "origin", origin, chdir: self
  end

  def git_head
    return unless git? && Utils.git_available?

    Utils.popen_read("git", "rev-parse", "--verify", "-q", "HEAD", chdir: self).chomp.presence
  end

  def git_short_head
    return unless git? && Utils.git_available?

    Utils.popen_read("git", "rev-parse", "--short=4", "--verify", "-q", "HEAD", chdir: self).chomp.presence
  end

  def git_last_commit
    return unless git? && Utils.git_available?

    Utils.popen_read("git", "show", "-s", "--format=%cr", "HEAD", chdir: self).chomp.presence
  end

  def git_branch
    return unless git? && Utils.git_available?

    Utils.popen_read("git", "rev-parse", "--abbrev-ref", "HEAD", chdir: self).chomp.presence
  end

  def git_last_commit_date
    return unless git? && Utils.git_available?

    Utils.popen_read("git", "show", "-s", "--format=%cd", "--date=short", "HEAD", chdir: self).chomp.presence
  end
end
