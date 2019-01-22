module Utils
  def self.clear_svn_version_cache
    remove_instance_variable(:@svn) if instance_variable_defined?(:@svn)
  end

  def self.svn_available?
    return @svn if instance_variable_defined?(:@svn)

    @svn = quiet_system HOMEBREW_SHIMS_PATH/"scm/svn", "--version"
  end

  def self.svn_remote_exists?(url)
    return true unless svn_available?

    # OK to unconditionally trust here because we're just checking if
    # a URL exists.
    quiet_system "svn", "ls", url, "--depth", "empty",
                 "--non-interactive", "--trust-server-cert"
  end
end
