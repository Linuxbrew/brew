require "testing_env"
require "utils/bottles"

class BottleCollectorTests < Homebrew::TestCase
  def setup
    @collector = Utils::Bottles::Collector.new
  end

  def checksum_for(tag)
    @collector.fetch_checksum_for(tag)
  end

  def test_collector_returns_passed_tags
    @collector[:lion] = "foo"
    @collector[:mountain_lion] = "bar"
    assert_equal ["bar", :mountain_lion], checksum_for(:mountain_lion)
  end

  def test_collector_returns_when_empty
    assert_nil checksum_for(:foo)
  end

  def test_collector_returns_nil_for_no_match
    @collector[:lion] = "foo"
    assert_nil checksum_for(:foo)
  end

  def test_collector_returns_nil_for_no_match_when_later_tag_present
    @collector[:lion_or_later] = "foo"
    assert_nil checksum_for(:foo)
  end

  def test_collector_prefers_exact_matches
    @collector[:lion_or_later] = "foo"
    @collector[:mountain_lion] = "bar"
    assert_equal ["bar", :mountain_lion], checksum_for(:mountain_lion)
  end
end
