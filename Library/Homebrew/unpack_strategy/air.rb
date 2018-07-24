module UnpackStrategy
  class Air
    include UnpackStrategy

    def self.can_extract?(path:, magic_number:)
      path.extname == ".air"
    end

    def dependencies
      @dependencies ||= [Hbc::CaskLoader.load("adobe-air")]
    end

    private

    def extract_to_dir(unpack_dir, basename:, verbose:)
      system_command!(
        "/Applications/Utilities/Adobe AIR Application Installer.app/Contents/MacOS/Adobe AIR Application Installer",
        args: ["-silent", "-location", unpack_dir, path],
      )
    end
  end
end
