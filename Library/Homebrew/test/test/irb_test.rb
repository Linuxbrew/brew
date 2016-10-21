require "helper/integration_command_test_case"

class IntegrationCommandTestIrb < IntegrationCommandTestCase
  def test_irb
    assert_match "'v8'.f # => instance of the v8 formula",
      cmd("irb", "--examples")

    setup_test_formula "testball"

    irb_test = HOMEBREW_TEMP/"irb-test.rb"
    irb_test.write <<-EOS.undent
      "testball".f
      :testball.f
      exit
    EOS

    assert_match "Interactive Homebrew Shell", cmd("irb", irb_test)
  end
end
