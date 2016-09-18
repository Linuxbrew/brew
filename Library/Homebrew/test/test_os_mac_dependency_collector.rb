require "testing_env"
require "dependency_collector"

class OSMacDependencyCollectorTests < Homebrew::TestCase
  def setup
    @d = DependencyCollector.new
  end

  def teardown
    DependencyCollector.clear_cache
  end

  def test_ld64_dep_pre_leopard
    MacOS.stubs(:version).returns(MacOS::Version.new("10.4"))
    assert_equal LD64Dependency.new, @d.build(:ld64)
  end

  def test_ld64_dep_leopard_or_newer
    MacOS.stubs(:version).returns(MacOS::Version.new("10.5"))
    assert_nil @d.build(:ld64)
  end

  def test_ant_dep_mavericks_or_newer
    skip "Only for Mac OS" unless OS.mac?
    MacOS.stubs(:version).returns(MacOS::Version.new("10.9"))
    @d.add :ant => :build
    assert_equal find_dependency("ant"), Dependency.new("ant", [:build])
  end

  def test_ant_dep_pre_mavericks
    skip "Only for Mac OS" unless OS.mac?
    MacOS.stubs(:version).returns(MacOS::Version.new("10.7"))
    @d.add :ant => :build
    assert_nil find_dependency("ant")
  end
end
