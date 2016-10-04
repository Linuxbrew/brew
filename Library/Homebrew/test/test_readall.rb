require "helper/integration_command_test_case"

class IntegrationCommandTestReadall < IntegrationCommandTestCase
  def test_readall
    formula_file = setup_test_formula "testball"
    alias_file = CoreTap.new.alias_dir/"foobar"
    alias_file.parent.mkpath
    FileUtils.ln_s formula_file, alias_file
    cmd("readall", "--aliases", "--syntax")
    cmd("readall", "homebrew/core")
  end
end
