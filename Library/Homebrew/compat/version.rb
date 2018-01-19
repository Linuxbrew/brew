class Version
  def slice(*)
    odisabled "Version#slice", "Version#to_s.slice"
  end
end
