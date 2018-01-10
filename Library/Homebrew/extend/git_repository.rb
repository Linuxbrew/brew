require "utils/git"
require "utils/popen"

module GitRepositoryExtension
  def git?
    join(".git").exist?
  end

  def git_origin
    return unless git? && Utils.git_available?
    cd do
      Utils.popen_read("git", "config", "--get", "remote.origin.url").chuzzle
    end
  end

  def git_head
    return unless git? && Utils.git_available?
    cd do
      Utils.popen_read("git", "rev-parse", "--verify", "-q", "HEAD").chuzzle
    end
  end

  def git_short_head
    return unless git? && Utils.git_available?
    cd do
      Utils.popen_read(
        "git", "rev-parse", "--short=4", "--verify", "-q", "HEAD"
      ).chuzzle
    end
  end

  def git_last_commit
    return unless git? && Utils.git_available?
    cd do
      Utils.popen_read("git", "show", "-s", "--format=%cr", "HEAD").chuzzle
    end
  end

  def git_branch
    return unless git? && Utils.git_available?
    cd do
      Utils.popen_read(
        "git", "rev-parse", "--abbrev-ref", "HEAD"
      ).chuzzle
    end
  end

  def git_last_commit_date
    return unless git? && Utils.git_available?
    cd do
      Utils.popen_read(
        "git", "show", "-s", "--format=%cd", "--date=short", "HEAD"
      ).chuzzle
    end
  end
end
