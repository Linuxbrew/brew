require "testing_env"
require "utils/bottles"

class OSMacBottleCollectorTests < Homebrew::TestCase
  def setup
    super
    @collector = Utils::Bottles::Collector.new
  end

  def checksum_for(tag)
    @collector.fetch_checksum_for(tag)
  end

  def test_collector_finds_or_later_tags
    @collector[:lion_or_later] = "foo"
    assert_equal ["foo", :lion_or_later], checksum_for(:mountain_lion)
    assert_nil checksum_for(:snow_leopard)
  end

  def test_collector_finds_altivec_tags
    @collector[:tiger_altivec] = "foo"
    assert_equal ["foo", :tiger_altivec], checksum_for(:tiger_g4)
    assert_equal ["foo", :tiger_altivec], checksum_for(:tiger_g4e)
    assert_equal ["foo", :tiger_altivec], checksum_for(:tiger_g5)
    assert_nil checksum_for(:tiger_g3)
  end
end
