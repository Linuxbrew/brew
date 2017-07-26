module Utils
  def self.svn_available?
    return @svn if instance_variable_defined?(:@svn)
    @svn = quiet_system HOMEBREW_SHIMS_PATH/"scm/svn", "--version"
  end

  def self.svn_remote_exists(url)
    return true unless svn_available?
    quiet_system "svn", "ls", url, "--depth", "empty"
  end
end
