require "testing_env"
require "hardware"

class HardwareTests < Homebrew::TestCase
  def test_hardware_cpu_type
    assert_includes [:intel, :ppc], Hardware::CPU.type
  end

  def test_hardware_intel_family
    families = [
      :core, :core2, :penryn, :nehalem, :arrandale, :sandybridge, :ivybridge, :haswell, :broadwell, :skylake,
      :westmere, :merom, :dothan, :atom, :presler, :prescott, :arm]
    assert_includes families, Hardware::CPU.family
  end
end
