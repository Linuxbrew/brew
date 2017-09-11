module InstallHelper
  module_function

  def self.install_without_artifacts(cask)
    Hbc::Installer.new(cask).tap do |i|
      i.download
      i.extract_primary_container
    end
  end

  def self.install_without_artifacts_with_caskfile(cask)
    Hbc::Installer.new(cask).tap do |i|
      i.download
      i.extract_primary_container
      i.save_caskfile
    end
  end

  def install_without_artifacts(cask)
    Hbc::Installer.new(cask).tap do |i|
      i.download
      i.extract_primary_container
    end
  end

  def install_with_caskfile(cask)
    Hbc::Installer.new(cask).tap(&:save_caskfile)
  end
end
