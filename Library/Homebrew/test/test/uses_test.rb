require "helper/integration_command_test_case"

class IntegrationCommandTestUses < IntegrationCommandTestCase
  def test_uses
    setup_test_formula "foo"
    setup_test_formula "bar"
    setup_test_formula "baz", <<-EOS.undent
      url "https://example.com/baz-1.0"
      depends_on "bar"
    EOS

    assert_equal "", cmd("uses", "baz")
    assert_equal "baz", cmd("uses", "bar")
    assert_equal "bar\nbaz", cmd("uses", "--recursive", "foo")
  end
end
