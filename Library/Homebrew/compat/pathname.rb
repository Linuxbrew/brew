class Pathname
  def cp(dst)
    odeprecated "Pathname#cp", "FileUtils.cp"
    if file?
      FileUtils.cp to_s, dst
    else
      FileUtils.cp_r to_s, dst
    end
    dst
  end

  def chmod_R(perms)
    odeprecated "Pathname#chmod_R", "FileUtils.chmod_R"
    require "fileutils"
    FileUtils.chmod_R perms, to_s
  end
end
