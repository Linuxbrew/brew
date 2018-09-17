class LazyObject < Delegator
  def initialize(&callable)
    super(callable)
  end

  def __getobj__
    return @__delegate__ if defined?(@__delegate__)

    @__delegate__ = @__callable__.call
  end

  def __setobj__(callable)
    @__callable__ = callable
  end
end
