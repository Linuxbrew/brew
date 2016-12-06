require "testing_env"
require "checksum"

class ChecksumTests < Homebrew::TestCase
  def test_empty?
    assert_empty Checksum.new(:sha256, "")
  end

  def test_equality
    a = Checksum.new(:sha256, TEST_SHA256)
    b = Checksum.new(:sha256, TEST_SHA256)
    assert_equal a, b

    a = Checksum.new(:sha256, TEST_SHA256)
    b = Checksum.new(:sha256, TEST_SHA256.reverse)
    refute_equal a, b

    a = Checksum.new(:sha1, TEST_SHA1)
    b = Checksum.new(:sha256, TEST_SHA256)
    refute_equal a, b
  end
end
