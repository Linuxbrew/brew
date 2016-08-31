require "testing_env"
require "fileutils"
require "pathname"
require "diagnostic"

class OSMacDiagnosticChecksTest < Homebrew::TestCase
  def setup
    @env = ENV.to_hash
    @checks = Homebrew::Diagnostic::Checks.new
  end

  def teardown
    ENV.replace(@env)
  end

  def test_check_for_other_package_managers
    MacOS.stubs(:macports_or_fink).returns ["fink"]
    assert_match "You have MacPorts or Fink installed:",
      @checks.check_for_other_package_managers
  end

  def test_check_for_unsupported_osx
    ARGV.stubs(:homebrew_developer?).returns false
    OS::Mac.stubs(:prerelease?).returns true
    assert_match "We do not provide support for this pre-release version.",
      @checks.check_for_unsupported_osx
  end

  def test_check_for_unsupported_curl_vars
    MacOS.stubs(:version).returns OS::Mac::Version.new("10.10")
    ENV["SSL_CERT_DIR"] = "/some/path"

    assert_match "SSL_CERT_DIR support was removed from Apple's curl.",
      @checks.check_for_unsupported_curl_vars
  end

  def test_check_for_beta_xquartz
    MacOS::XQuartz.stubs(:version).returns("2.7.10_beta2")
    assert_match "The following beta release of XQuartz is installed: 2.7.10_beta2", @checks.check_for_beta_xquartz
  end
end
