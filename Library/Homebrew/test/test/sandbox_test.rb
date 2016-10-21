require "testing_env"
require "sandbox"

class SandboxTest < Homebrew::TestCase
  def setup
    skip "sandbox not implemented" unless Sandbox.available?
    @sandbox = Sandbox.new
    @dir = Pathname.new(mktmpdir)
    @file = @dir/"foo"
  end

  def teardown
    @dir.rmtree
  end

  def test_formula?
    f = formula { url "foo-1.0" }
    f2 = formula { url "bar-1.0" }
    f2.stubs(:tap).returns(Tap.fetch("test/tap"))

    ARGV.stubs(:sandbox?).returns true
    assert Sandbox.formula?(f),
      "Formulae should be sandboxed if --sandbox was passed."

    ARGV.stubs(:sandbox?).returns false
    assert Sandbox.formula?(f),
      "Formulae should be sandboxed if in a sandboxed tap."
    refute Sandbox.formula?(f2),
        "Formulae should not be sandboxed if not in a sandboxed tap."
  end

  def test_test?
    ARGV.stubs(:no_sandbox?).returns false
    assert Sandbox.test?,
      "Tests should be sandboxed unless --no-sandbox was passed."
  end

  def test_allow_write
    @sandbox.allow_write @file
    @sandbox.exec "touch", @file
    assert_predicate @file, :exist?
  end

  def test_deny_write
    shutup do
      assert_raises(ErrorDuringExecution) { @sandbox.exec "touch", @file }
    end
    refute_predicate @file, :exist?
  end

  def test_complains_on_failure
    Utils.expects(popen_read: "foo")
    ARGV.stubs(verbose?: true)
    out, _err = capture_io do
      assert_raises(ErrorDuringExecution) { @sandbox.exec "false" }
    end
    assert_match "foo", out
  end

  def test_ignores_bogus_python_error
    with_bogus_error = <<-EOS.undent
      foo
      Mar 17 02:55:06 sandboxd[342]: Python(49765) deny file-write-unlink /System/Library/Frameworks/Python.framework/Versions/2.7/lib/python2.7/distutils/errors.pyc
      bar
    EOS
    Utils.expects(popen_read: with_bogus_error)
    ARGV.stubs(verbose?: true)
    out, _err = capture_io do
      assert_raises(ErrorDuringExecution) { @sandbox.exec "false" }
    end
    refute_predicate out, :empty?
    assert_match "foo", out
    assert_match "bar", out
    refute_match "Python", out
  end
end
