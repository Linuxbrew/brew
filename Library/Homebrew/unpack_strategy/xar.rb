module UnpackStrategy
  class Xar
    include UnpackStrategy

    def self.can_extract?(path:, magic_number:)
      magic_number.match?(/\Axar!/n)
    end

    private

    def extract_to_dir(unpack_dir, basename:, verbose:)
      system_command! "xar", args: ["-x", "-f", path, "-C", unpack_dir]
    end
  end
end
