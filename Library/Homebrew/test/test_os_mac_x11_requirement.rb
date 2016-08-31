require "testing_env"
require "requirements/x11_requirement"

class OSMacX11RequirementTests < Homebrew::TestCase
  def test_satisfied
    MacOS::XQuartz.stubs(:version).returns("2.7.5")
    MacOS::XQuartz.stubs(:installed?).returns(true)
    assert_predicate X11Requirement.new, :satisfied?

    MacOS::XQuartz.stubs(:installed?).returns(false)
    refute_predicate X11Requirement.new, :satisfied?
  end
end
