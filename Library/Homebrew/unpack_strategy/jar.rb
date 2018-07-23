require_relative "uncompressed"

module UnpackStrategy
  class Jar < Uncompressed
    def self.can_extract?(path:, magic_number:)
      return false unless Zip.can_extract?(path: path, magic_number: magic_number)

      # Check further if the ZIP is a JAR/WAR.
      out, = Open3.capture3("zipinfo", "-1", path)
      out.encode(Encoding::UTF_8, invalid: :replace)
         .split("\n")
         .include?("META-INF/MANIFEST.MF")
    end
  end
end
