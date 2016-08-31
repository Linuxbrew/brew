class Keg
  def fname
    odeprecated "Keg#fname", "Keg#name"
    name
  end
end
