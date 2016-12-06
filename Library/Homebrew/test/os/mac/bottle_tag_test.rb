require "testing_env"
require "utils/bottles"

class OSMacBottleTagTests < Homebrew::TestCase
  def test_tag_tiger_ppc
    MacOS.stubs(:version).returns(MacOS::Version.new("10.4"))
    Hardware::CPU.stubs(:type).returns(:ppc)
    Hardware::CPU.stubs(:family).returns(:foo)
    MacOS.stubs(:prefer_64_bit?).returns(false)
    assert_equal :tiger_foo, Utils::Bottles.tag
  end

  def test_tag_tiger_intel
    MacOS.stubs(:version).returns(MacOS::Version.new("10.4"))
    Hardware::CPU.stubs(:type).returns(:intel)
    MacOS.stubs(:prefer_64_bit?).returns(false)
    assert_equal :tiger, Utils::Bottles.tag
  end

  def test_tag_tiger_ppc_64
    MacOS.stubs(:version).returns(MacOS::Version.new("10.4"))
    Hardware::CPU.stubs(:type).returns(:ppc)
    Hardware::CPU.stubs(:family).returns(:g5)
    MacOS.stubs(:prefer_64_bit?).returns(true)
    assert_equal :tiger_g5_64, Utils::Bottles.tag
  end

  # Note that this will probably never be used
  def test_tag_tiger_intel_64
    MacOS.stubs(:version).returns(MacOS::Version.new("10.4"))
    Hardware::CPU.stubs(:type).returns(:intel)
    MacOS.stubs(:prefer_64_bit?).returns(true)
    assert_equal :tiger_64, Utils::Bottles.tag
  end

  def test_tag_leopard_intel
    MacOS.stubs(:version).returns(MacOS::Version.new("10.5"))
    Hardware::CPU.stubs(:type).returns(:intel)
    MacOS.stubs(:prefer_64_bit?).returns(false)
    assert_equal :leopard, Utils::Bottles.tag
  end

  def test_tag_leopard_ppc_64
    MacOS.stubs(:version).returns(MacOS::Version.new("10.5"))
    Hardware::CPU.stubs(:type).returns(:ppc)
    Hardware::CPU.stubs(:family).returns(:g5)
    MacOS.stubs(:prefer_64_bit?).returns(true)
    assert_equal :leopard_g5_64, Utils::Bottles.tag
  end

  def test_tag_leopard_intel_64
    MacOS.stubs(:version).returns(MacOS::Version.new("10.5"))
    Hardware::CPU.stubs(:type).returns(:intel)
    MacOS.stubs(:prefer_64_bit?).returns(true)
    assert_equal :leopard_64, Utils::Bottles.tag
  end

  def test_tag_snow_leopard_32
    MacOS.stubs(:version).returns(MacOS::Version.new("10.6"))
    Hardware::CPU.stubs(:is_64_bit?).returns(false)
    assert_equal :snow_leopard_32, Utils::Bottles.tag
  end

  def test_tag_snow_leopard_64
    MacOS.stubs(:version).returns(MacOS::Version.new("10.6"))
    Hardware::CPU.stubs(:is_64_bit?).returns(true)
    assert_equal :snow_leopard, Utils::Bottles.tag
  end

  def test_tag_lion
    MacOS.stubs(:version).returns(MacOS::Version.new("10.7"))
    assert_equal :lion, Utils::Bottles.tag
  end

  def test_tag_mountain_lion
    MacOS.stubs(:version).returns(MacOS::Version.new("10.8"))
    assert_equal :mountain_lion, Utils::Bottles.tag
  end
end
