require "fcntl"

class FormulaLock
  def initialize(name)
    @name = name
    @path = HOMEBREW_LOCK_DIR/"#{@name}.brewing"
    @lockfile = nil
  end

  def lock
    HOMEBREW_LOCK_DIR.mkpath
    @lockfile = get_or_create_lockfile
    unless @lockfile.flock(File::LOCK_EX | File::LOCK_NB)
      raise OperationInProgressError, @name
    end
  end

  def unlock
    unless @lockfile.nil? || @lockfile.closed?
      @lockfile.flock(File::LOCK_UN)
      @lockfile.close
    end
  end

  def with_lock
    lock
    yield
  ensure
    unlock
  end

  private

  def get_or_create_lockfile
    if @lockfile.nil? || @lockfile.closed?
      @lockfile = @path.open(File::RDWR | File::CREAT)
      @lockfile.fcntl(Fcntl::F_SETFD, Fcntl::FD_CLOEXEC)
      @lockfile
    else
      @lockfile
    end
  end
end
