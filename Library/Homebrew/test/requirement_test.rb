require "testing_env"
require "requirement"

class RequirementTests < Homebrew::TestCase
  class TestRequirement < Requirement; end

  def test_accepts_single_tag
    dep = Requirement.new(%w[bar])
    assert_equal %w[bar], dep.tags
  end

  def test_accepts_multiple_tags
    dep = Requirement.new(%w[bar baz])
    assert_equal %w[bar baz].sort, dep.tags.sort
  end

  def test_option_names
    dep = TestRequirement.new
    assert_equal %w[test], dep.option_names
  end

  def test_preserves_symbol_tags
    dep = Requirement.new([:build])
    assert_equal [:build], dep.tags
  end

  def test_accepts_symbol_and_string_tags
    dep = Requirement.new([:build, "bar"])
    assert_equal [:build, "bar"], dep.tags
  end

  def test_dsl_fatal
    req = Class.new(Requirement) { fatal true }.new
    assert_predicate req, :fatal?
  end

  def test_satisfy_true
    req = Class.new(Requirement) do
      satisfy(build_env: false) { true }
    end.new
    assert_predicate req, :satisfied?
  end

  def test_satisfy_false
    req = Class.new(Requirement) do
      satisfy(build_env: false) { false }
    end.new
    refute_predicate req, :satisfied?
  end

  def test_satisfy_with_boolean
    req = Class.new(Requirement) do
      satisfy true
    end.new
    assert_predicate req, :satisfied?
  end

  def test_satisfy_sets_up_build_env_by_default
    req = Class.new(Requirement) do
      satisfy { true }
    end.new

    ENV.expects(:with_build_environment).yields.returns(true)

    assert_predicate req, :satisfied?
  end

  def test_satisfy_build_env_can_be_disabled
    req = Class.new(Requirement) do
      satisfy(build_env: false) { true }
    end.new

    ENV.expects(:with_build_environment).never

    assert_predicate req, :satisfied?
  end

  def test_infers_path_from_satisfy_result
    which_path = Pathname.new("/foo/bar/baz")
    req = Class.new(Requirement) do
      satisfy { which_path }
    end.new

    ENV.expects(:with_build_environment).yields.returns(which_path)
    ENV.expects(:append_path).with("PATH", which_path.parent)

    req.satisfied?
    req.modify_build_environment
  end

  def test_dsl_build
    req = Class.new(Requirement) { build true }.new
    assert_predicate req, :build?
  end

  def test_infer_name_from_class
    const = :FooRequirement
    klass = self.class

    klass.const_set(const, Class.new(Requirement))

    begin
      assert_equal "foo", klass.const_get(const).new.name
    ensure
      klass.send(:remove_const, const)
    end
  end

  def test_dsl_default_formula
    req = Class.new(Requirement) { default_formula "foo" }.new
    assert_predicate req, :default_formula?
  end

  def test_to_dependency
    req = Class.new(Requirement) { default_formula "foo" }.new
    assert_equal Dependency.new("foo"), req.to_dependency
  end

  def test_to_dependency_calls_requirement_modify_build_environment
    error = Class.new(StandardError)

    req = Class.new(Requirement) do
      default_formula "foo"
      satisfy { true }
      env { raise error }
    end.new

    assert_raises(error) do
      req.to_dependency.modify_build_environment
    end
  end

  def test_modify_build_environment_without_env_proc
    assert_nil Class.new(Requirement).new.modify_build_environment
  end

  def test_eql
    a = Requirement.new
    b = Requirement.new
    assert_equal a, b
    assert_eql a, b
    assert_equal a.hash, b.hash
  end

  def test_not_eql
    a = Requirement.new([:optional])
    b = Requirement.new
    refute_equal a, b
    refute_eql a, b
    refute_equal a.hash, b.hash
  end
end
