require "testing_env"

class IntegrationCommandTestFormula < IntegrationCommandTestCase
  def test_formula
    formula_file = setup_test_formula "testball"
    assert_equal formula_file.to_s, cmd("formula", "testball")
  end
end
