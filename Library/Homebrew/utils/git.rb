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
end
