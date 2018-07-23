require_relative "uncompressed"

module UnpackStrategy
  class MicrosoftOfficeXml < Uncompressed
    def self.can_extract?(path:, magic_number:)
      return false unless Zip.can_extract?(path: path, magic_number: magic_number)

      # Check further if the ZIP is a Microsoft Office XML document.
      magic_number.match?(/\APK\003\004/n) &&
        magic_number.match?(%r{\A.{30}(\[Content_Types\]\.xml|_rels/\.rels)}n)
    end
  end
end
