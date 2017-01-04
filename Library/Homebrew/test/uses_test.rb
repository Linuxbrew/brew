require "testing_env"

class IntegrationCommandTestUses < IntegrationCommandTestCase
  def test_uses
    setup_test_formula "foo"
    setup_test_formula "bar"
    setup_test_formula "baz", <<-EOS.undent
      url "https://example.com/baz-1.0"
      depends_on "bar"
    EOS

    # Unset HOMEBREW_VERBOSE_USING_DOTS, as a dot in the output fails this test.
    env = { "HOMEBREW_VERBOSE_USING_DOTS" => nil }
    assert_equal "", cmd("uses", "baz", env)
    assert_equal "baz", cmd("uses", "bar", env)
    assert_match(/(bar\nbaz|baz\nbar)/, cmd("uses", "--recursive", "foo", env))
  end
end
