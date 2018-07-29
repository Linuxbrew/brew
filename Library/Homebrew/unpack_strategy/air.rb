module UnpackStrategy
  class Air
    include UnpackStrategy

    using Magic

    def self.can_extract?(path)
      mime_type = "application/vnd.adobe.air-application-installer-package+zip"
      path.magic_number.match?(/.{59}#{Regexp.escape(mime_type)}/)
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
