class Formula
  def patches
    # Don't print deprecation warning because this method is inherited
    # when used.
    {}
  end

  def rake(*)
    odisabled "FileUtils#rake", "system \"rake\""
  end
end
