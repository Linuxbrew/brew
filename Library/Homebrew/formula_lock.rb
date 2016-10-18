require "fcntl"

class FormulaLock
  def initialize(name)
    @name = name
    @path = HOMEBREW_LOCK_DIR/"#{@name}.brewing"
    @lockfile = nil
  end

  def lock
    @path.parent.mkpath
    create_lockfile
    return if @lockfile.flock(File::LOCK_EX | File::LOCK_NB)
    raise OperationInProgressError, @name
  end

  def unlock
    return if @lockfile.nil? || @lockfile.closed?
    @lockfile.flock(File::LOCK_UN)
    @lockfile.close
  end

  def with_lock
    lock
    yield
  ensure
    unlock
  end

  private

  def create_lockfile
    return unless @lockfile.nil? || @lockfile.closed?
    @lockfile = @path.open(File::RDWR | File::CREAT)
    @lockfile.fcntl(Fcntl::F_SETFD, Fcntl::FD_CLOEXEC)
  end
end
