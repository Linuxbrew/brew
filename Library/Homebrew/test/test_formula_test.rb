require "testing_env"

class IntegrationCommandTestTestFormula < IntegrationCommandTestCase
  def test_test_formula
    assert_match "This command requires a formula argument", cmd_fail("test")
    assert_match "Testing requires the latest version of testball",
      cmd_fail("test", testball)

    cmd("install", testball)
    assert_match "testball defines no test", cmd_fail("test", testball)

    setup_test_formula "testball_copy", <<-EOS.undent
      head "https://github.com/example/testball2.git"

      devel do
        url "file://#{TEST_FIXTURE_DIR}/tarballs/testball-0.1.tbz"
        sha256 "#{TESTBALL_SHA256}"
      end

      keg_only "just because"

      test do
      end
    EOS

    cmd("install", "testball_copy")
    assert_match "Testing testball_copy", cmd("test", "--HEAD", "testball_copy")
    # This test is currently failing on Linux:
    # Error: Testing requires the latest version of testball_copy
    return if OS.linux?
    assert_match "Testing testball_copy", cmd("test", "--devel", "testball_copy")
  end
end
