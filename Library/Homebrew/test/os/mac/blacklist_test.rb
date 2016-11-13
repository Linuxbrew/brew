require "testing_env"
require "blacklist"

class OSMacBlacklistTests < Homebrew::TestCase
  def assert_blacklisted(s)
    assert blacklisted?(s), "'#{s}' should be blacklisted"
  end

  def test_xcode
    %w[xcode Xcode].each { |s| assert_blacklisted s }
  end
end
