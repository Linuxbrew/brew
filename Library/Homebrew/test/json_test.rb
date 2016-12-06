require "testing_env"
require "json"

class JsonSmokeTest < Homebrew::TestCase
  def test_encode
    hash = { "foo" => ["bar", "baz"] }
    json = '{"foo":["bar","baz"]}'
    assert_equal json, JSON.generate(hash)
  end

  def test_decode
    hash = { "foo" => ["bar", "baz"], "qux" => 1 }
    json = '{"foo":["bar","baz"],"qux":1}'
    assert_equal hash, JSON.parse(json)
  end

  def test_decode_failure
    assert_raises(JSON::ParserError) { JSON.parse("nope") }
  end
end
