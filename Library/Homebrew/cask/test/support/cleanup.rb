module MiniTest
  class Spec
    def after_teardown
      super
      Hbc.installed.each do |cask|
        Hbc::Installer.new(cask).purge_versioned_files
      end
    end
  end
end
