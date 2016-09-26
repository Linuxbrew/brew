require "integration_cmds_tests"

class IntegrationCommandTestDeps < IntegrationCommandTests
  def test_deps
    setup_test_formula "foo"
    setup_test_formula "bar"
    setup_test_formula "baz", <<-EOS.undent
      url "https://example.com/baz-1.0"
      depends_on "bar"
    EOS

    assert_equal "", cmd("deps", "foo")
    assert_equal "foo", cmd("deps", "bar")
    assert_equal "bar\nfoo", cmd("deps", "baz")
  end
end
