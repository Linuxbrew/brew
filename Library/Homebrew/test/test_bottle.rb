require "helper/integration_command_test_case"

class IntegrationCommandTestBottle < IntegrationCommandTestCase
  def test_bottle
    cmd("install", "--build-bottle", testball)
    assert_match "Formula not from core or any taps",
                 cmd_fail("bottle", "--no-rebuild", testball)

    setup_test_formula "testball"

    # `brew bottle` should not fail with dead symlink
    # https://github.com/Homebrew/legacy-homebrew/issues/49007
    (HOMEBREW_CELLAR/"testball/0.1").cd do
      FileUtils.ln_s "not-exist", "symlink"
    end
    assert_match(/testball-0\.1.*\.bottle\.tar\.gz/,
                  cmd_output("bottle", "--no-rebuild", "testball"))
  ensure
    FileUtils.rm_f Dir["testball-0.1*.bottle.tar.gz"]
  end
end
