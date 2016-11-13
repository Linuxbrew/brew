require "testing_env"

class IntegrationCommandTestCat < IntegrationCommandTestCase
  def test_cat
    formula_file = setup_test_formula "testball"
    assert_equal formula_file.read.chomp, cmd("cat", "testball")
  end
end
