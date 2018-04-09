class Formula
  def rake(*)
    odisabled "FileUtils#rake", "system \"rake\""
  end
end
