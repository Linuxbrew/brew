require "integration_cmds_tests"

class IntegrationCommandTestFetch < IntegrationCommandTests
  def test_fetch
    setup_test_formula "testball"

    cmd("fetch", "testball")
    assert((HOMEBREW_CACHE/"testball-0.1.tbz").exist?,
      "The tarball should have been cached")
  end
end
