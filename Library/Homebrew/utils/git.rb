require "open3"

module Git
  module_function

  def last_revision_commit_of_file(repo, file, before_commit: nil)
    args = [before_commit.nil? ? "--skip=1" : before_commit.split("..").first]

    out, = Open3.capture3(
      HOMEBREW_SHIMS_PATH/"scm/git", "-C", repo,
      "log", "--oneline", "--max-count=1", *args, "--", file
    )
    out.split(" ").first
  end

  def last_revision_of_file(repo, file, before_commit: nil)
    relative_file = Pathname(file).relative_path_from(repo)

    commit_hash = last_revision_commit_of_file(repo, relative_file, before_commit: before_commit)
    out, = Open3.capture3(
      HOMEBREW_SHIMS_PATH/"scm/git", "-C", repo,
      "show", "#{commit_hash}:#{relative_file}"
    )
    out
  end
end

module Utils
  def self.git_available?
    return @git if instance_variable_defined?(:@git)
    @git = quiet_system HOMEBREW_SHIMS_PATH/"scm/git", "--version"
  end

  def self.git_path
    return unless git_available?
    @git_path ||= Utils.popen_read(
      HOMEBREW_SHIMS_PATH/"scm/git", "--homebrew=print-path"
    ).chuzzle
  end

  def self.git_version
    return unless git_available?
    @git_version ||= Utils.popen_read(
      HOMEBREW_SHIMS_PATH/"scm/git", "--version"
    ).chomp[/git version (\d+(?:\.\d+)*)/, 1]
  end

  def self.ensure_git_installed!
    return if git_available?

    # we cannot install brewed git if homebrew/core is unavailable.
    raise "Git is unavailable" unless CoreTap.instance.installed?

    begin
      oh1 "Installing git"
      safe_system HOMEBREW_BREW_FILE, "install", "git"
    rescue
      raise "Git is unavailable"
    end

    clear_git_available_cache
    raise "Git is unavailable" unless git_available?
  end

  def self.clear_git_available_cache
    remove_instance_variable(:@git) if instance_variable_defined?(:@git)
    @git_path = nil
    @git_version = nil
  end

  def self.git_remote_exists(url)
    return true unless git_available?
    quiet_system "git", "ls-remote", url
  end
end
