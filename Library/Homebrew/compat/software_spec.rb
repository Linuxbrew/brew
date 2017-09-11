class BottleSpecification
  def revision(*args)
    odeprecated "BottleSpecification.revision", "BottleSpecification.rebuild"
    rebuild(*args)
  end
end
