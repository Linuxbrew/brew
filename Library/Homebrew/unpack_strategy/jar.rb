require_relative "uncompressed"

module UnpackStrategy
  class Jar < Uncompressed
    using Magic

    def self.extensions
      [".apk", ".jar"]
    end

    def self.can_extract?(path)
      return false unless Zip.can_extract?(path)

      # Check further if the ZIP is a JAR/WAR.
      path.zipinfo.include?("META-INF/MANIFEST.MF")
    end
  end
end
