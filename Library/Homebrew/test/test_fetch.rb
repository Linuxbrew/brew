require "helper/integration_command_test_case"

class IntegrationCommandTestFetch < IntegrationCommandTestCase
  def test_fetch
    setup_test_formula "testball"

    cmd("fetch", "testball")
    assert((HOMEBREW_CACHE/"testball-0.1.tbz").exist?,
      "The tarball should have been cached")
  end
end
