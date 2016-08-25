class BottleSpecification
  def revision(*args)
    # Don't announce deprecation yet as this is quite a big change
    # to a public interface.
    # odeprecated "BottleSpecification.revision", "BottleSpecification.rebuild"
    rebuild(*args)
  end
end
