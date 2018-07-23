require_relative "uncompressed"

module UnpackStrategy
  class LuaRock < Uncompressed
    def self.can_extract?(path:, magic_number:)
      return false unless Zip.can_extract?(path: path, magic_number: magic_number)

      # Check further if the ZIP is a LuaRocks package.
      out, = Open3.capture3("zipinfo", "-1", path)
      out.encode(Encoding::UTF_8, invalid: :replace)
         .split("\n")
         .any? { |line| line.match?(%r{\A[^/]+.rockspec\Z}) }
    end
  end
end
