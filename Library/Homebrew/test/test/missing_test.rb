require "helper/integration_command_test_case"

class IntegrationCommandTestMissing < IntegrationCommandTestCase
  def setup
    super

    setup_test_formula "foo"
    setup_test_formula "bar"
  end

  def make_prefix(name)
    (HOMEBREW_CELLAR/name/"1.0").mkpath
  end

  def test_missing_missing
    make_prefix "bar"

    assert_match "foo", cmd("missing")
  end

  def test_missing_not_missing
    make_prefix "foo"
    make_prefix "bar"

    assert_empty cmd("missing")
  end

  def test_missing_hide
    make_prefix "foo"
    make_prefix "bar"

    assert_match "foo", cmd("missing", "--hide=foo")
  end
end
