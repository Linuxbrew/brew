class Version
  def slice(*args)
    odeprecated "Version#slice", "Version#to_s.slice"
    to_s.slice(*args)
  end
end
