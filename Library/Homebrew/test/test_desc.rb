require "helper/integration_command_test_case"

class IntegrationCommandTestDesc < IntegrationCommandTestCase
  def test_desc
    setup_test_formula "testball"

    assert_equal "testball: Some test", cmd("desc", "testball")
    assert_match "Pick one, and only one", cmd_fail("desc", "--search", "--name")
    assert_match "You must provide a search term", cmd_fail("desc", "--search")

    desc_cache = HOMEBREW_CACHE/"desc_cache.json"
    refute_predicate desc_cache, :exist?, "Cached file should not exist"

    cmd("desc", "--description", "testball")
    assert_predicate desc_cache, :exist?, "Cached file should not exist"
  end
end
