require "testing_env"
require "formula_lock"

class FormulaLockTests < Homebrew::TestCase
  def setup
    super
    @lock = FormulaLock.new("foo")
    @lock.lock
  end

  def teardown
    @lock.unlock
    super
  end

  def test_locking_file_with_existing_lock_raises_error
    assert_raises(OperationInProgressError) { FormulaLock.new("foo").lock }
  end

  def test_locking_existing_lock_suceeds
    assert_nothing_raised { @lock.lock }
  end
end
