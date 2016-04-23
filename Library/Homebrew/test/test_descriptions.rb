require "testing_env"
require "descriptions"

class DescriptionsTest < Homebrew::TestCase
  def setup
    @descriptions_hash = {}
    @descriptions = Descriptions.new(@descriptions_hash)

    @old_stdout = $stdout
    $stdout = StringIO.new
  end

  def teardown
    $stdout = @old_stdout
  end

  def test_single_core_formula
    @descriptions_hash["homebrew/core/foo"] = "Core foo"
    @descriptions.print
    assert_equal "foo: Core foo", $stdout.string.chomp
  end

  def test_single_external_formula
    @descriptions_hash["somedev/external/foo"] = "External foo"
    @descriptions.print
    assert_equal "foo: External foo", $stdout.string.chomp
  end

  def test_even_dupes
    @descriptions_hash["homebrew/core/foo"] = "Core foo"
    @descriptions_hash["somedev/external/foo"] = "External foo"
    @descriptions.print
    assert_equal "homebrew/core/foo: Core foo\nsomedev/external/foo: External foo",
                 $stdout.string.chomp
  end

  def test_odd_dupes
    @descriptions_hash["homebrew/core/foo"] = "Core foo"
    @descriptions_hash["somedev/external/foo"] = "External foo"
    @descriptions_hash["otherdev/external/foo"] = "Other external foo"
    @descriptions.print
    assert_equal "homebrew/core/foo: Core foo\notherdev/external/foo: Other external foo\nsomedev/external/foo: External foo",
                 $stdout.string.chomp
  end
end
