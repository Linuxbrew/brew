class Pathname
  def cp(_)
    odisabled "Pathname#cp", "FileUtils.cp"
  end

  def chmod_R(_)
    odisabled "Pathname#chmod_R", "FileUtils.chmod_R"
  end
end
