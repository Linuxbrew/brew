require "helper/integration_command_test_case"

class IntegrationCommandTestLeaves < IntegrationCommandTestCase
  def test_leaves
    setup_test_formula "foo"
    setup_test_formula "bar"
    assert_equal "", cmd("leaves")

    (HOMEBREW_CELLAR/"foo/0.1/somedir").mkpath
    assert_equal "foo", cmd("leaves")

    (HOMEBREW_CELLAR/"bar/0.1/somedir").mkpath
    assert_equal "bar", cmd("leaves")
  end
end
