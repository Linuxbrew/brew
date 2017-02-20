require "testing_env"
require "requirements/java_requirement"

class JavaRequirementTests < Homebrew::TestCase
  def setup
    super
    ENV["JAVA_HOME"] = nil
  end

  def test_message
    a = JavaRequirement.new([])
    assert_match(/Java is required to install this formula./, a.message)
  end

  def test_inspect
    a = JavaRequirement.new(%w[1.7+])
    assert_equal a.inspect, '#<JavaRequirement: "java" [] version="1.7+">'
  end

  def test_display_s
    x = JavaRequirement.new([])
    assert_equal x.display_s, "java"
    y = JavaRequirement.new(%w[1.8])
    assert_equal y.display_s, "java = 1.8"
    z = JavaRequirement.new(%w[1.8+])
    assert_equal z.display_s, "java >= 1.8"
  end

  def test_satisfied?
    a = JavaRequirement.new(%w[1.8])
    File.stubs(:executable?).returns(false)
    refute_predicate a, :satisfied?

    b = JavaRequirement.new([])
    b.stubs(:preferred_java).returns(Pathname.new("/usr/bin/java"))
    assert_predicate b, :satisfied?

    c = JavaRequirement.new(%w[1.7+])
    c.stubs(:possible_javas).returns([Pathname.new("/usr/bin/java")])
    Utils.stubs(:popen_read).returns('java version "1.6.0_5"')
    refute_predicate c, :satisfied?
    Utils.stubs(:popen_read).returns('java version "1.8.0_5"')
    assert_predicate c, :satisfied?

    d = JavaRequirement.new(%w[1.7])
    d.stubs(:possible_javas).returns([Pathname.new("/usr/bin/java")])
    Utils.stubs(:popen_read).returns('java version "1.8.0_5"')
    refute_predicate d, :satisfied?
  end
end
