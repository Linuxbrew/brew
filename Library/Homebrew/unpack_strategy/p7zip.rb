module UnpackStrategy
  class P7Zip
    include UnpackStrategy

    def self.can_extract?(path:, magic_number:)
      magic_number.match?(/\A7z\xBC\xAF\x27\x1C/n)
    end

    def dependencies
      @dependencies ||= [Formula["p7zip"]]
    end

    private

    def extract_to_dir(unpack_dir, basename:, verbose:)
      safe_system "7zr", "x", "-y", "-bd", "-bso0", path, "-o#{unpack_dir}"
    end
  end
end
